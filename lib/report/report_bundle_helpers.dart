/// DevAudit
///
/// Copyright (c) Pharos Labs.
/// Licensed under the Apache License, Version 2.0.
library;

import 'package:path/path.dart' as p;

import '../core/model/audit_issue.dart';

/// Groups [issues] by [keyOf], preserving the order keys first appear in.
///
/// Since [issues] is always already sorted by file path, then line, then
/// column, then rule ID (a guarantee [AuditEngine] provides), this yields
/// deterministic, sorted group order and per-group issue order for free —
/// callers never need to re-sort.
Map<String, List<AuditIssue>> groupIssuesBy(
  List<AuditIssue> issues,
  String Function(AuditIssue issue) keyOf,
) {
  final groups = <String, List<AuditIssue>>{};
  for (final issue in issues) {
    groups.putIfAbsent(keyOf(issue), () => []).add(issue);
  }
  return groups;
}

/// The folder an issue belongs to: the forward-slash parent directory of
/// [AuditIssue.filePath].
///
/// [AuditIssue.filePath] is always forward-slash-normalized regardless of
/// host platform, so this always uses POSIX path semantics
/// (`package:path`'s platform-default context must not be used here, since
/// on Windows it would split on backslashes instead).
String folderOf(AuditIssue issue) => p.posix.dirname(issue.filePath);

/// Renders [issue] as a single Markdown bullet line, in the format shared
/// by every generator that lists issues (per-file, per-folder, and agent
/// task reports).
String renderIssueBullet(AuditIssue issue) {
  final evidence = issue.evidence;
  final evidenceSuffix = evidence == null ? '' : ' ($evidence)';
  return '- `${issue.range.startLine}:${issue.range.startColumn}` '
      '**${issue.severity.name}** ${issue.message}$evidenceSuffix '
      '`[${issue.ruleId}]`';
}
