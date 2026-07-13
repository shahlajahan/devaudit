/// DevAudit
///
/// Copyright (c) Pharos Labs.
/// Licensed under the Apache License, Version 2.0.
library;

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'audit_severity.dart';
import 'source_range.dart';

const _mapEquality = DeepCollectionEquality();

/// A single finding produced by a rule during an audit.
///
/// An [AuditIssue] is a plain, immutable data holder. It carries a
/// deterministic JSON representation so reporters never need
/// code-generation to serialize it.
///
/// [filePath] must always be a normalized, forward-slash, project-relative
/// path (for example `lib/home_page.dart`). Absolute, machine-specific paths
/// must never be stored here, since issues are surfaced directly in
/// reports.
///
/// Since: 0.1.0-dev.1
@immutable
class AuditIssue {
  /// Creates an audit issue.
  ///
  /// [filePath] is expected to already be normalized (relative,
  /// forward-slash) by the caller before this constructor is invoked — see
  /// the path normalization layer and the plugin that produced this issue.
  /// This constructor performs no validation of its own, to keep
  /// [AuditIssue] a pure immutable value object and preserve `const`
  /// construction.
  const AuditIssue({
    required this.ruleId,
    required this.severity,
    required this.message,
    required this.filePath,
    required this.range,
    this.evidence,
    this.suggestion,
    this.metadata,
  });

  /// The stable ID of the rule that produced this issue, for example
  /// `flutter.localization.hardcoded-ui-string`.
  final String ruleId;

  /// How important this finding is.
  final AuditSeverity severity;

  /// A human-readable description of the finding.
  final String message;

  /// The normalized, project-relative path (forward slashes) of the file
  /// the finding was found in.
  final String filePath;

  /// Where in the file the finding is located.
  final SourceRange range;

  /// The raw source text that triggered the finding, if available.
  final String? evidence;

  /// A suggested next step to resolve the finding, if available.
  final String? suggestion;

  /// Additional, rule-specific data, if it adds real value to consumers.
  final Map<String, Object?>? metadata;

  /// A deterministic JSON representation of this issue.
  ///
  /// `evidence`, `suggestion`, and `metadata` are omitted entirely when
  /// absent, rather than serialized as `null`.
  Map<String, Object?> toJson() => {
    'ruleId': ruleId,
    'severity': severity.name,
    'message': message,
    'filePath': filePath,
    'range': range.toJson(),
    if (evidence != null) 'evidence': evidence,
    if (suggestion != null) 'suggestion': suggestion,
    if (metadata != null) 'metadata': metadata,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuditIssue &&
        other.ruleId == ruleId &&
        other.severity == severity &&
        other.message == message &&
        other.filePath == filePath &&
        other.range == range &&
        other.evidence == evidence &&
        other.suggestion == suggestion &&
        _mapEquality.equals(other.metadata, metadata);
  }

  @override
  int get hashCode => Object.hash(
    ruleId,
    severity,
    message,
    filePath,
    range,
    evidence,
    suggestion,
    metadata == null ? null : _mapEquality.hash(metadata),
  );

  /// Returns a short debugging summary combining [filePath], [range],
  /// [severity], [ruleId], and [message].
  ///
  /// This format is not a stable public contract: it may change between
  /// versions, and consumers must not parse it.
  @override
  String toString() => '$filePath:$range $severity $ruleId: $message';
}
