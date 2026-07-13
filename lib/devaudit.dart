/// DevAudit
///
/// Copyright (c) Pharos Labs.
/// Licensed under the Apache License, Version 2.0.
///
/// A plugin-based developer audit platform. Analyze. Understand. Improve.
///
/// This library exports the stable public API surface consumers may build
/// against directly: the core domain model, the plugin/rule/reporter
/// contracts, the audit engine, the built-in Flutter plugin, and the
/// built-in reporters. Internal implementation details (AST visitors, file
/// discovery helpers, and so on) are intentionally not exported.
library;

// Core domain model.
export 'core/model/audit_context.dart';
export 'core/model/audit_issue.dart';
export 'core/model/audit_result.dart';
export 'core/model/audit_severity.dart';
export 'core/model/source_location.dart';
export 'core/model/source_range.dart';

// Core contracts.
export 'core/plugin/audit_plugin.dart';
export 'core/report/audit_reporter.dart';
export 'core/rule/audit_rule.dart';
export 'core/rule/audit_rule_metadata.dart';

// Core engine.
export 'core/engine/audit_engine.dart';

// Built-in plugins.
export 'plugins/flutter/flutter_audit_plugin.dart';

// Built-in reporters.
export 'report/console_reporter.dart';
export 'report/json_reporter.dart' hide toolVersion;
