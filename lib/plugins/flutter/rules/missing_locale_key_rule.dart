/// DevAudit
///
/// Copyright (c) Pharos Labs.
/// Licensed under the Apache License, Version 2.0.
library;

import 'package:path/path.dart' as p;

import '../../../core/model/audit_issue.dart';
import '../../../core/model/audit_severity.dart';
import '../../../core/model/source_location.dart';
import '../../../core/model/source_range.dart';
import '../../../core/rule/audit_rule.dart';
import '../../../core/rule/audit_rule_metadata.dart';
import '../arb/arb_document.dart';

/// Detects localization keys present in a reference ARB file but missing
/// from one or more other locale ARB files.
///
/// Since: 0.1.0-dev.1
class MissingLocaleKeyRule extends AuditRule {
  /// Creates the missing locale key rule.
  const MissingLocaleKeyRule();

  /// The stable metadata for this rule.
  static const AuditRuleMetadata ruleMetadata = AuditRuleMetadata(
    id: 'flutter.localization.missing-locale-key',
    name: 'Missing locale key',
    description:
        'Detects localization keys present in the reference ARB file but '
        'missing from one or more locale ARB files.',
    defaultSeverity: AuditSeverity.warning,
    category: AuditCategory.localization,
  );

  @override
  AuditRuleMetadata get metadata => ruleMetadata;

  /// Evaluates this rule against already-parsed ARB documents.
  ///
  /// [reference] is the ARB file every document in [locales] is compared
  /// against. Each key present in [reference] but absent from a given
  /// locale document produces one [AuditIssue], located at that locale
  /// document — never at [reference].
  List<AuditIssue> evaluate({
    required ArbDocument reference,
    required List<ArbDocument> locales,
  }) {
    final issues = <AuditIssue>[];
    for (final locale in locales) {
      final missingKeys = reference.keys.difference(locale.keys).toList()
        ..sort();
      final fileName = p.basename(locale.path);

      for (final key in missingKeys) {
        issues.add(
          AuditIssue(
            ruleId: metadata.id,
            severity: metadata.defaultSeverity,
            message: 'Localization key "$key" is missing from $fileName.',
            filePath: locale.path,
            range: const SourceRange(start: SourceLocation(line: 1, column: 1)),
            evidence: key,
            suggestion: 'Add the "$key" key to $fileName.',
          ),
        );
      }
    }
    return issues;
  }
}
