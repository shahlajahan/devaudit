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

/// Generates one Markdown document per source file that has findings,
/// mirroring the source tree exactly: a file at `lib/ui/vet_page.dart`
/// gets a report at `files/lib/ui/vet_page.dart.md`.
///
/// Mirroring the source tree (rather than flattening the path into one
/// name) makes path collisions structurally impossible, keeps a report's
/// source file obvious from its own path, and keeps links from
/// `summary.md` predictable — see ADR-0003.
///
/// A file with no findings gets no document; there is nothing useful to
/// say about it here.
///
/// Since: 0.1.0-dev.1
class PerFileMarkdownBundleGenerator extends ReportBundleGenerator {
  /// Creates a per-file Markdown bundle generator.
  const PerFileMarkdownBundleGenerator();

  @override
  ReportBundle generate(AuditResult result, {required String target}) {
    final byFile = groupIssuesBy(result.issues, (issue) => issue.filePath);

    return ReportBundle(
      documents: [
        for (final entry in byFile.entries)
          ReportDocument(
            path: 'files/${entry.key}.md',
            content: _render(entry.key, entry.value),
          ),
      ],
    );
  }

  String _render(String filePath, List<AuditIssue> issues) {
    final buffer = StringBuffer()
      ..writeln('# $filePath')
      ..writeln()
      ..writeln('${issues.length} finding(s).')
      ..writeln();

    for (final issue in issues) {
      buffer.writeln(renderIssueBullet(issue));
      final suggestion = issue.suggestion;
      if (suggestion != null) {
        buffer.writeln('  - Suggestion: $suggestion');
      }
    }

    return buffer.toString();
  }
}
