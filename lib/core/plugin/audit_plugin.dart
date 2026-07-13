/// DevAudit
///
/// Copyright (c) Pharos Labs.
/// Licensed under the Apache License, Version 2.0.
library;

import 'package:meta/meta.dart';

import '../model/audit_context.dart';
import '../model/audit_issue.dart';
import '../rule/audit_rule_metadata.dart';

/// The result a plugin returns after analyzing a project.
///
/// Since: 0.1.0-dev.1
@immutable
class PluginAnalysisResult {
  /// Creates a plugin analysis result.
  const PluginAnalysisResult({
    required this.issues,
    required this.filesScanned,
  });

  /// The issues found by the plugin.
  final List<AuditIssue> issues;

  /// How many files the plugin scanned.
  final int filesScanned;
}

/// The public contract every DevAudit plugin must implement.
///
/// A plugin owns everything specific to one ecosystem: discovering which
/// files are relevant, parsing them, running its rules, and returning
/// issues. The core engine only knows how to call [analyze]; it has no
/// notion of what "Flutter" or "Dart" (or any other ecosystem) means.
///
/// Since: 0.1.0-dev.1
abstract class AuditPlugin {
  /// Allows subclasses to be `const`.
  const AuditPlugin();

  /// The stable, unique identifier of this plugin, for example `flutter`.
  String get id;

  /// A human-readable name for this plugin, for example `Flutter`.
  String get displayName;

  /// Metadata for every rule this plugin can produce issues for.
  List<AuditRuleMetadata> get rules;

  /// Whether this plugin is able to analyze the file at [filePath].
  ///
  /// [filePath] may be absolute or relative; implementations should only
  /// rely on its extension and name.
  bool supports(String filePath);

  /// Analyzes the project described by [context] and returns the issues
  /// found.
  ///
  /// Implementations must not throw for expected, recoverable problems such
  /// as an unreadable or syntactically invalid file; those should be
  /// skipped so the rest of the project can still be analyzed. Throwing is
  /// reserved for conditions the engine should treat as a full plugin
  /// failure.
  Future<PluginAnalysisResult> analyze(AuditContext context);
}
