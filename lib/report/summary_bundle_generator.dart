/// DevAudit
///
/// Copyright (c) Pharos Labs.
/// Licensed under the Apache License, Version 2.0.
library;

import 'dart:convert';

import '../core/model/audit_issue.dart';
import '../core/model/audit_result.dart';
import '../core/report/report_bundle.dart';
import '../core/report/report_bundle_generator.dart';
import '../shared/tool_version.dart';
import 'report_bundle_helpers.dart';

/// Generates `summary.md` and `summary.json`: the at-a-glance view of a
/// scan — totals, a breakdown by severity and rule, and hotspot tables of
/// findings per folder and per file, each linking to the corresponding
/// per-file/per-folder report document.
///
/// Since: 0.1.0-dev.1
class SummaryBundleGenerator extends ReportBundleGenerator {
  /// Creates a summary bundle generator.
  const SummaryBundleGenerator();

  /// The version of the `summary.json` schema this generator produces.
  ///
  /// Tracked independently from [JsonReporter.schemaVersion]: the two
  /// documents have unrelated shapes, and a breaking change to one must
  /// not force a version bump on the other, even though both currently
  /// start at `"1.0"`.
  static const schemaVersion = '1.0';

  /// The maximum number of rows shown in `summary.md`'s "by folder"/"by
  /// file" tables. This only shortens the Markdown summary for
  /// readability on large scans; `summary.json`'s `byFolder`/`byFile`
  /// arrays are never truncated, and the full per-folder/per-file
  /// documents always exist regardless of this limit.
  static const maxSummaryTableRows = 20;

  @override
  ReportBundle generate(AuditResult result, {required String target}) {
    final byRule = <String, int>{};
    for (final issue in result.issues) {
      byRule[issue.ruleId] = (byRule[issue.ruleId] ?? 0) + 1;
    }

    final byFile = _sortedCounts(
      groupIssuesBy(result.issues, (i) => i.filePath),
    );
    final byFolder = _sortedCounts(groupIssuesBy(result.issues, folderOf));

    return ReportBundle(
      documents: [
        ReportDocument(
          path: 'summary.md',
          content: _renderMarkdown(result, byRule, byFolder, byFile),
        ),
        ReportDocument(
          path: 'summary.json',
          content: _renderJson(result, target, byRule, byFolder, byFile),
        ),
      ],
    );
  }

  List<MapEntry<String, int>> _sortedCounts(
    Map<String, List<AuditIssue>> groups,
  ) {
    final counts = groups.entries
        .map((e) => MapEntry(e.key, e.value.length))
        .toList();
    counts.sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      return byCount != 0 ? byCount : a.key.compareTo(b.key);
    });
    return counts;
  }

  String _renderMarkdown(
    AuditResult result,
    Map<String, int> byRule,
    List<MapEntry<String, int>> byFolder,
    List<MapEntry<String, int>> byFile,
  ) {
    final affectedFiles = result.issues
        .map((issue) => issue.filePath)
        .toSet()
        .length;

    final buffer = StringBuffer()
      ..writeln('# DevAudit Summary')
      ..writeln()
      ..writeln('- Files scanned: ${result.filesScanned}')
      ..writeln('- Affected files: $affectedFiles')
      ..writeln('- Issues: ${result.issues.length}')
      ..writeln('- Info: ${result.infoCount}')
      ..writeln('- Warnings: ${result.warningCount}')
      ..writeln('- Errors: ${result.errorCount}')
      ..writeln('- Duration: ${result.duration.inMilliseconds} ms');

    if (byRule.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## Findings by rule')
        ..writeln()
        ..writeln('| Rule | Count |')
        ..writeln('| --- | --- |');
      for (final entry in byRule.entries) {
        buffer.writeln('| `${entry.key}` | ${entry.value} |');
      }
    }

    if (byFolder.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## Findings by folder')
        ..writeln()
        ..writeln('| Folder | Count |')
        ..writeln('| --- | --- |');
      for (final entry in byFolder.take(maxSummaryTableRows)) {
        buffer.writeln(
          '| [${entry.key}](folders/${entry.key}.md) | ${entry.value} |',
        );
      }
      buffer
        ..writeln()
        ..writeln('See folders/ for the complete folder reports.');
    }

    if (byFile.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## Findings by file (hotspots)')
        ..writeln()
        ..writeln('| File | Count |')
        ..writeln('| --- | --- |');
      for (final entry in byFile.take(maxSummaryTableRows)) {
        buffer.writeln(
          '| [${entry.key}](files/${entry.key}.md) | ${entry.value} |',
        );
      }
      buffer
        ..writeln()
        ..writeln('See files/ for the complete per-file reports.');
    }

    if (result.issues.isEmpty) {
      buffer
        ..writeln()
        ..writeln('No issues found.');
    }

    return buffer.toString();
  }

  String _renderJson(
    AuditResult result,
    String target,
    Map<String, int> byRule,
    List<MapEntry<String, int>> byFolder,
    List<MapEntry<String, int>> byFile,
  ) {
    final json = <String, Object?>{
      'schemaVersion': schemaVersion,
      'tool': {'name': 'devaudit', 'version': toolVersion},
      'target': target,
      'summary': {
        'filesScanned': result.filesScanned,
        'issues': result.issues.length,
      },
      'bySeverity': {
        'info': result.infoCount,
        'warning': result.warningCount,
        'error': result.errorCount,
      },
      'byRule': byRule,
      'byFolder': [
        for (final e in byFolder) {'path': e.key, 'count': e.value},
      ],
      'byFile': [
        for (final e in byFile) {'path': e.key, 'count': e.value},
      ],
    };
    return const JsonEncoder.withIndent('  ').convert(json);
  }
}
