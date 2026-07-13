/// DevAudit
///
/// Copyright (c) Pharos Labs.
/// Licensed under the Apache License, Version 2.0.
library;

import 'audit_rule_metadata.dart';

/// The public contract that a rule exposed by an [AuditPlugin] must
/// implement.
///
/// [AuditRule] exists solely to expose [metadata] through a common,
/// semantic contract shared by every rule in every plugin — see ADR-0002
/// ("Rule Execution Boundary"). It intentionally carries no behavioral
/// members (no `execute()`, `evaluate()`, or `analyze()`) and must not be
/// expanded to add any:
///
/// - The core never invokes a rule directly, and never will as a matter of
///   architecture, not merely because no rule needs it yet.
/// - Plugins own rule execution entirely. How a rule actually evaluates
///   source code (an AST visitor for Dart, a token scanner for another
///   language, a manifest-file reader for a dependency-health check) is
///   language- and plugin-specific, and stays internal to the plugin that
///   owns it.
/// - The engine only ever calls [AuditPlugin.analyze]; it asks a plugin to
///   analyze and return issues, and never asks a rule to do anything.
///
/// Since: 0.1.0-dev.1
abstract class AuditRule {
  /// Allows subclasses to be `const`.
  const AuditRule();

  /// The stable metadata describing this rule.
  AuditRuleMetadata get metadata;
}
