/// DevAudit
///
/// Copyright (c) Pharos Labs.
/// Licensed under the Apache License, Version 2.0.
library;

import 'dart:io';

import 'package:args/command_runner.dart';

import '../core/engine/audit_engine.dart';
import '../core/model/audit_context.dart';
import '../core/model/audit_result.dart';
import '../core/report/audit_reporter.dart';
import '../plugins/flutter/flutter_audit_plugin.dart';
import '../report/console_reporter.dart';
import '../report/json_reporter.dart';
import 'exit_codes.dart';

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

    final AuditReporter reporter = format == 'json'
        ? const JsonReporter()
        : const ConsoleReporter();
    final rendered = reporter.render(result, target: targetArg);

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

  int _exitCodeFor(AuditResult result, String failOn) {
    final reached = switch (failOn) {
      'none' => false,
      'warning' => result.warningCount > 0 || result.errorCount > 0,
      'error' => result.errorCount > 0,
      _ => false,
    };
    return reached ? failThresholdExitCode : 0;
  }
}
