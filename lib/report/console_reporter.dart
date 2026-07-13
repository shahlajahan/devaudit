/// DevAudit
///
/// Copyright (c) Pharos Labs.
/// Licensed under the Apache License, Version 2.0.
library;

import '../core/model/audit_issue.dart';
import '../core/model/audit_result.dart';
import '../core/report/audit_reporter.dart';

/// Renders an [AuditResult] as human-readable text, grouped by file.
///
/// Output never uses ANSI colors: correctness and stability across
/// terminals, redirected output, and CI logs matter more than color for
/// this report format.
///
/// Since: 0.1.0-dev.1
class ConsoleReporter extends AuditReporter {
  /// Creates a console reporter.
  const ConsoleReporter();

  @override
  String render(AuditResult result, {required String target}) {
    final buffer = StringBuffer()..writeln('DevAudit');

    if (result.issues.isEmpty) {
      buffer
        ..writeln()
        ..writeln('No issues found.');
    } else {
      final issuesByFile = <String, List<AuditIssue>>{};
      for (final issue in result.issues) {
        issuesByFile.putIfAbsent(issue.filePath, () => []).add(issue);
      }

      for (final entry in issuesByFile.entries) {
        buffer
          ..writeln()
          ..writeln(entry.key);
        for (final issue in entry.value) {
          buffer.writeln(
            '  ${_position(issue)}  ${issue.severity.name.padRight(7)}  '
            '${_describe(issue)}',
          );
        }
      }
    }

    buffer
      ..writeln()
      ..writeln('Summary')
      ..writeln('  Files scanned: ${result.filesScanned}')
      ..writeln('  Issues: ${result.issues.length}')
      ..writeln('  Info: ${result.infoCount}')
      ..writeln('  Warnings: ${result.warningCount}')
      ..writeln('  Errors: ${result.errorCount}')
      ..writeln('  Duration: ${result.duration.inMilliseconds} ms');

    for (final summary in result.pluginSummaries) {
      if (!summary.succeeded) {
        buffer.writeln(
          '  Warning: plugin "${summary.pluginId}" failed: ${summary.error}',
        );
      }
    }

    return buffer.toString();
  }

  String _position(AuditIssue issue) =>
      '${issue.range.startLine}:${issue.range.startColumn}';

  String _describe(AuditIssue issue) {
    final evidence = issue.evidence;
    final suffix = evidence == null ? '' : ' ($evidence)';
    return '${issue.message}$suffix  [${issue.ruleId}]';
  }
}
