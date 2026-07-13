/// DevAudit
///
/// Copyright (c) Pharos Labs.
/// Licensed under the Apache License, Version 2.0.
library;

import '../core/model/audit_issue.dart';
import '../core/model/audit_result.dart';
import '../core/report/report_bundle.dart';
import '../core/report/report_bundle_generator.dart';
import 'report_bundle_helpers.dart';

/// Generates one Markdown document per folder that has findings, mirroring
/// the source tree: findings under `lib/ui/pet_taxi/` get a report at
/// `folders/lib/ui/pet_taxi.md`.
///
/// A folder's document groups its findings by file, so a folder spanning
/// several files stays navigable rather than one flat list.
///
/// Since: 0.1.0-dev.1
class FolderMarkdownBundleGenerator extends ReportBundleGenerator {
  /// Creates a folder Markdown bundle generator.
  const FolderMarkdownBundleGenerator();

  @override
  ReportBundle generate(AuditResult result, {required String target}) {
    final byFolder = groupIssuesBy(result.issues, folderOf);

    return ReportBundle(
      documents: [
        for (final entry in byFolder.entries)
          ReportDocument(
            path: 'folders/${entry.key}.md',
            content: _render(entry.key, entry.value),
          ),
      ],
    );
  }

  String _render(String folderPath, List<AuditIssue> issues) {
    final byFile = groupIssuesBy(issues, (issue) => issue.filePath);

    final buffer = StringBuffer()
      ..writeln('# $folderPath')
      ..writeln()
      ..writeln('${issues.length} finding(s) across ${byFile.length} file(s).');

    for (final entry in byFile.entries) {
      buffer
        ..writeln()
        ..writeln('## ${entry.key}')
        ..writeln();
      for (final issue in entry.value) {
        buffer.writeln(renderIssueBullet(issue));
      }
    }

    return buffer.toString();
  }
}
