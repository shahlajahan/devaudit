/// DevAudit
///
/// Copyright (c) Pharos Labs.
/// Licensed under the Apache License, Version 2.0.
library;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/line_info.dart';

import '../../../core/model/audit_issue.dart';
import '../../../core/model/audit_severity.dart';
import '../../../core/rule/audit_rule.dart';
import '../../../core/rule/audit_rule_metadata.dart';
import '../analyzer/hardcoded_string_visitor.dart';

final _fileSuppressionPattern = RegExp(
  r'//\s*devaudit-ignore-file:\s*([\w.\-]+)',
);

/// Detects probable user-visible strings hardcoded directly into Flutter UI
/// widgets, instead of being sourced from the project's localization
/// resources.
///
/// See `docs/rules/flutter-hardcoded-ui-string.md` for the full list of
/// detected APIs and suppression syntax.
///
/// Since: 0.1.0-dev.1
class HardcodedUiStringRule extends AuditRule {
  /// Creates the hardcoded UI string rule.
  const HardcodedUiStringRule();

  /// The stable metadata for this rule.
  static const AuditRuleMetadata ruleMetadata = AuditRuleMetadata(
    id: 'flutter.localization.hardcoded-ui-string',
    name: 'Hardcoded UI string',
    description:
        'Detects probable user-visible strings hardcoded directly into '
        "Flutter UI widgets instead of being sourced from the project's "
        'localization resources.',
    defaultSeverity: AuditSeverity.warning,
    category: AuditCategory.localization,
  );

  @override
  AuditRuleMetadata get metadata => ruleMetadata;

  /// Evaluates this rule against an already-parsed file.
  ///
  /// [relativePath] must already be normalized. [source] is the raw file
  /// content, used to look up suppression comments and file-level
  /// suppression.
  List<AuditIssue> evaluate({
    required String relativePath,
    required String source,
    required CompilationUnit unit,
    required LineInfo lineInfo,
  }) {
    final sourceLines = source.split('\n');
    if (_isFileSuppressed(sourceLines)) return const [];

    final visitor = HardcodedStringVisitor(
      ruleId: metadata.id,
      severity: metadata.defaultSeverity,
      relativePath: relativePath,
      lineInfo: lineInfo,
      sourceLines: sourceLines,
    );
    unit.accept(visitor);
    return visitor.issues;
  }

  bool _isFileSuppressed(List<String> sourceLines) {
    for (final line in sourceLines) {
      final match = _fileSuppressionPattern.firstMatch(line);
      if (match != null && match.group(1) == metadata.id) return true;
    }
    return false;
  }
}
