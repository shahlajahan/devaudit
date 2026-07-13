/// DevAudit
///
/// Copyright (c) Pharos Labs.
/// Licensed under the Apache License, Version 2.0.
library;

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../core/engine/audit_engine.dart';
import '../core/model/audit_context.dart';
import '../core/model/audit_result.dart';
import '../core/model/audit_severity.dart';
import '../core/report/audit_reporter.dart';
import '../core/report/report_bundle.dart';
import '../core/report/report_bundle_generator.dart';
import '../plugins/flutter/flutter_audit_plugin.dart';
import '../report/agent_task_bundle_generator.dart';
import '../report/console_reporter.dart';
import '../report/folder_markdown_bundle_generator.dart';
import '../report/json_reporter.dart';
import '../report/per_file_markdown_bundle_generator.dart';
import '../report/summary_bundle_generator.dart';
import 'exit_codes.dart';
import 'report_bundle_composer.dart';
import 'report_bundle_writer.dart';

/// Implements `devaudit scan [target]`.
///
/// Since: 0.1.0-dev.1
class ScanCommand extends Command<int> {
  /// Creates the scan command and registers its options.
  ScanCommand() {
    argParser
      ..addOption(
        'format',
        allowed: ['console', 'json'],
        defaultsTo: 'console',
        help: 'The report format to produce.',
      )
      ..addOption(
        'output',
        help: 'Write the report to this file instead of stdout.',
      )
      ..addOption(
        'fail-on',
        allowed: ['none', 'warning', 'error'],
        defaultsTo: 'error',
        help: 'The minimum severity that causes a non-zero exit code.',
      )
      ..addOption(
        'min-severity',
        allowed: ['info', 'warning', 'error'],
        defaultsTo: 'info',
        help:
            'The minimum severity to include in the rendered report. Does '
            'not affect --fail-on, which always evaluates the full, '
            'unfiltered scan.',
      )
      ..addMultiOption(
        'include',
        help: 'Additional files or directories to include.',
      )
      ..addMultiOption(
        'exclude',
        help: 'Additional path substrings to exclude.',
      )
      ..addFlag(
        'verbose',
        negatable: false,
        help: 'Print extra diagnostic information to stderr.',
      )
      ..addFlag(
        'report',
        negatable: false,
        help:
            'Generate a multi-file report bundle (summary.md, summary.json, '
            'and one Markdown file per source file with findings) under '
            '--report-dir, in addition to any --format/--output report.',
      )
      ..addOption(
        'report-dir',
        defaultsTo: 'devaudit-report',
        help:
            'Directory to write --report/--report-folders/--agent-tasks '
            'output to. Requires --report.',
      )
      ..addFlag(
        'report-folders',
        negatable: false,
        help:
            'Additionally generate folder-grouped Markdown reports. '
            'Requires --report.',
      )
      ..addFlag(
        'agent-tasks',
        negatable: false,
        help:
            'Additionally generate an AI-agent task bundle under '
            '<report-dir>/agent/. Requires --report.',
      );
  }

  @override
  String get name => 'scan';

  @override
  String get description => 'Scans a project and reports audit findings.';

  @override
  String get invocation => 'devaudit scan [target]';

  @override
  Future<int> run() async {
    final args = argResults!;

    if (args.rest.length > 1) {
      usageException(
        'Too many arguments. Expected at most one target directory.',
      );
    }

    final report = args.flag('report');
    final reportFolders = args.flag('report-folders');
    final agentTasks = args.flag('agent-tasks');
    if (!report) {
      if (reportFolders) usageException('--report-folders requires --report.');
      if (agentTasks) usageException('--agent-tasks requires --report.');
      if (args.wasParsed('report-dir')) {
        usageException('--report-dir requires --report.');
      }
    }

    final targetArg = args.rest.isEmpty ? '.' : args.rest.single;

    final targetDirectory = Directory(targetArg);
    if (!targetDirectory.existsSync()) {
      stderr.writeln(
        'devaudit: target "$targetArg" does not exist or is not a directory.',
      );
      return executionErrorExitCode;
    }

    final format = args.option('format')!;
    final failOn = args.option('fail-on')!;
    final minSeverity = AuditSeverity.values.byName(
      args.option('min-severity')!,
    );
    final outputPath = args.option('output');
    final include = args.multiOption('include');
    final exclude = args.multiOption('exclude');
    final verbose = args.flag('verbose');

    final context = AuditContext(
      projectRoot: targetDirectory.absolute.path,
      include: include,
      exclude: exclude,
    );

    final engine = AuditEngine(plugins: const [FlutterAuditPlugin()]);
    final AuditResult result;
    try {
      result = await engine.run(context);
    } catch (error) {
      stderr.writeln('devaudit: scan failed: $error');
      return executionErrorExitCode;
    }

    if (verbose) {
      for (final summary in result.pluginSummaries) {
        final status = summary.succeeded ? '' : ' (failed: ${summary.error})';
        stderr.writeln(
          'devaudit: plugin "${summary.pluginId}" scanned ${summary.filesScanned} file(s)$status.',
        );
      }
    }

    // Only the rendered report is filtered; --fail-on below always
    // evaluates the original, unfiltered result, so hiding issues from the
    // report never changes CI behavior.
    final renderedResult = result.filteredBySeverity(minSeverity);
    final reportDir = Directory(args.option('report-dir')!);

    // The bundle is written before the primary report, so that a compact
    // "Report directory: ..." summary is only ever shown once that
    // directory has actually been written successfully — not before a
    // failure that would otherwise leave it looking misleading.
    if (report) {
      final exitCode = _writeReportBundle(
        renderedResult,
        target: targetArg,
        reportDir: reportDir,
        includeFolders: reportFolders,
        includeAgentTasks: agentTasks,
        verbose: verbose,
      );
      if (exitCode != null) return exitCode;
    }

    // With --report, the console format switches to a compact summary:
    // every finding already lives in the report bundle, and printing all
    // of them again is unusable on large projects. --format=json is
    // unaffected either way.
    final String rendered;
    if (report && format == 'console') {
      rendered = _renderCompactSummary(
        renderedResult,
        reportDir: reportDir,
        includeAgentTasks: agentTasks,
      );
    } else {
      final AuditReporter reporter = format == 'json'
          ? const JsonReporter()
          : const ConsoleReporter();
      rendered = reporter.render(renderedResult, target: targetArg);
    }

    if (outputPath != null) {
      try {
        File(outputPath).writeAsStringSync(rendered);
      } on FileSystemException catch (error) {
        stderr.writeln(
          'devaudit: could not write report to "$outputPath": ${error.message}',
        );
        return executionErrorExitCode;
      }
    } else {
      stdout.write(rendered);
      if (!rendered.endsWith('\n')) stdout.writeln();
    }

    return _exitCodeFor(result, failOn);
  }

  /// Renders the compact summary shown instead of the full console report
  /// when `--report` is set: every finding already lives in the report
  /// bundle at [reportDir], so there is no reason to print them all again.
  ///
  /// Points at the most useful entry points to open first —
  /// `summary.md`/`summary.json`, and the agent task bundle when
  /// [includeAgentTasks] is set — rather than just naming the directory
  /// and leaving the user to explore it themselves.
  String _renderCompactSummary(
    AuditResult result, {
    required Directory reportDir,
    required bool includeAgentTasks,
  }) {
    final buffer = StringBuffer()
      ..writeln('DevAudit')
      ..writeln()
      ..writeln('Summary')
      ..writeln('  Files scanned: ${result.filesScanned}')
      ..writeln('  Issues: ${result.issues.length}')
      ..writeln('  Warnings: ${result.warningCount}')
      ..writeln('  Errors: ${result.errorCount}')
      ..writeln('  Duration: ${result.duration.inMilliseconds} ms')
      ..writeln()
      ..writeln('Reports written to:')
      ..writeln()
      ..writeln('  ${p.join(reportDir.path, 'summary.md')}')
      ..writeln('  ${p.join(reportDir.path, 'summary.json')}');

    if (includeAgentTasks) {
      buffer
        ..writeln()
        ..writeln('AI agent bundle:')
        ..writeln('  ${p.join(reportDir.path, 'agent')}/');
    }

    return buffer.toString();
  }

  int _exitCodeFor(AuditResult result, String failOn) {
    final reached = switch (failOn) {
      'none' => false,
      'warning' => result.warningCount > 0 || result.errorCount > 0,
      'error' => result.errorCount > 0,
      _ => false,
    };
    return reached ? failThresholdExitCode : 0;
  }

  /// Generates and writes the `--report` bundle. Returns an exit code to
  /// return immediately on failure, or `null` on success.
  int? _writeReportBundle(
    AuditResult renderedResult, {
    required String target,
    required Directory reportDir,
    required bool includeFolders,
    required bool includeAgentTasks,
    required bool verbose,
  }) {
    final generators = <ReportBundleGenerator>[
      const SummaryBundleGenerator(),
      const PerFileMarkdownBundleGenerator(),
      if (includeFolders) const FolderMarkdownBundleGenerator(),
      if (includeAgentTasks) const AgentTaskBundleGenerator(),
    ];

    final ReportBundle composed;
    try {
      composed = const ReportBundleComposer().compose([
        for (final generator in generators)
          generator.generate(renderedResult, target: target),
      ]);
    } on StateError catch (error) {
      stderr.writeln(
        'devaudit: could not build report bundle: ${error.message}',
      );
      return executionErrorExitCode;
    }

    try {
      writeReportBundle(composed, outputDir: reportDir);
    } on UnsafeReportDirectoryException catch (error) {
      stderr.writeln('devaudit: $error');
      return executionErrorExitCode;
    } on FileSystemException catch (error) {
      stderr.writeln(
        'devaudit: could not write report bundle: ${error.message}',
      );
      return executionErrorExitCode;
    }

    if (verbose) {
      stderr.writeln(
        'devaudit: wrote ${composed.documents.length} report document(s) to '
        '${reportDir.path}',
      );
    }
    return null;
  }
}
