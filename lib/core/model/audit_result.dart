/// DevAudit
///
/// Copyright (c) Pharos Labs.
/// Licensed under the Apache License, Version 2.0.
library;

import 'package:meta/meta.dart';

import 'audit_issue.dart';
import 'audit_severity.dart';

/// The outcome of running a single plugin during an audit.
///
/// This is primarily useful for diagnostics: it lets a report or CLI
/// explain how many files a plugin looked at, or why a plugin contributed
/// no issues (because it failed).
///
/// Since: 0.1.0-dev.1
@immutable
class PluginExecutionSummary {
  /// Creates a plugin execution summary.
  const PluginExecutionSummary({
    required this.pluginId,
    required this.filesScanned,
    this.error,
  });

  /// The ID of the plugin this summary describes.
  final String pluginId;

  /// How many files the plugin scanned before finishing or failing.
  final int filesScanned;

  /// A human-readable description of why the plugin failed, or `null` if it
  /// completed successfully.
  final String? error;

  /// Whether the plugin completed without throwing.
  bool get succeeded => error == null;

  /// A deterministic JSON representation of this summary.
  ///
  /// `error` is omitted entirely when the plugin succeeded, rather than
  /// serialized as `null`.
  Map<String, Object?> toJson() => {
    'pluginId': pluginId,
    'filesScanned': filesScanned,
    'succeeded': succeeded,
    if (error != null) 'error': error,
  };
}

/// The combined result of running an [AuditEngine] over one or more
/// plugins.
///
/// An [AuditResult] represents a completed scan: it is effectively frozen
/// after construction. [issues] and [pluginSummaries] are defensively
/// copied so that no reporter or other consumer can modify or reorder them
/// after the fact — in particular, [issues] carries the engine's
/// deterministic ordering guarantee, and nothing may silently invalidate
/// it.
///
/// Since: 0.1.0-dev.1
@immutable
class AuditResult {
  /// Creates an audit result.
  AuditResult({
    required List<AuditIssue> issues,
    required this.filesScanned,
    required this.duration,
    List<PluginExecutionSummary> pluginSummaries = const [],
  }) : issues = List.unmodifiable(issues),
       pluginSummaries = List.unmodifiable(pluginSummaries);

  /// Every issue collected across all plugins, in deterministic order.
  final List<AuditIssue> issues;

  /// The total number of files scanned across all plugins.
  final int filesScanned;

  /// How long the audit took to run.
  final Duration duration;

  /// Per-plugin execution details, useful for diagnostics.
  final List<PluginExecutionSummary> pluginSummaries;

  /// The number of issues with [AuditSeverity.info].
  int get infoCount => _countOf(AuditSeverity.info);

  /// The number of issues with [AuditSeverity.warning].
  int get warningCount => _countOf(AuditSeverity.warning);

  /// The number of issues with [AuditSeverity.error].
  int get errorCount => _countOf(AuditSeverity.error);

  int _countOf(AuditSeverity severity) =>
      issues.where((issue) => issue.severity == severity).length;

  /// A deterministic JSON representation of this result.
  Map<String, Object?> toJson() => {
    'filesScanned': filesScanned,
    'durationMs': duration.inMilliseconds,
    'issueCount': issues.length,
    'infoCount': infoCount,
    'warningCount': warningCount,
    'errorCount': errorCount,
    'pluginSummaries': pluginSummaries
        .map((summary) => summary.toJson())
        .toList(),
    'issues': issues.map((issue) => issue.toJson()).toList(),
  };
}
