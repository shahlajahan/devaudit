/// DevAudit
///
/// Copyright (c) Pharos Labs.
/// Licensed under the Apache License, Version 2.0.
library;

import '../model/audit_context.dart';
import '../model/audit_issue.dart';
import '../model/audit_result.dart';
import '../plugin/audit_plugin.dart';

/// Runs a set of [AuditPlugin]s against an [AuditContext] and combines their
/// output into a single, deterministically ordered [AuditResult].
///
/// The engine has no knowledge of any specific ecosystem: it only knows how
/// to invoke plugins, catch and record their failures, merge their issues,
/// and sort the result. It never formats output; that is the reporter's
/// job.
///
/// Since: 0.1.0-dev.1
class AuditEngine {
  /// Creates an engine that will run [plugins], in order, over whatever
  /// context it is given.
  AuditEngine({required List<AuditPlugin> plugins})
    : _plugins = List.unmodifiable(plugins);

  final List<AuditPlugin> _plugins;

  /// Runs every registered plugin against [context] and returns the
  /// combined result.
  ///
  /// If an individual plugin throws, the engine records the failure in
  /// [AuditResult.pluginSummaries] and continues with the remaining
  /// plugins rather than aborting the whole audit.
  Future<AuditResult> run(AuditContext context) async {
    final stopwatch = Stopwatch()..start();
    final issues = <AuditIssue>[];
    final summaries = <PluginExecutionSummary>[];
    var filesScanned = 0;

    for (final plugin in _plugins) {
      try {
        final result = await plugin.analyze(context);
        issues.addAll(result.issues);
        filesScanned += result.filesScanned;
        summaries.add(
          PluginExecutionSummary(
            pluginId: plugin.id,
            filesScanned: result.filesScanned,
          ),
        );
      } catch (error) {
        summaries.add(
          PluginExecutionSummary(
            pluginId: plugin.id,
            filesScanned: 0,
            error: error.toString(),
          ),
        );
      }
    }

    issues.sort(_compareIssues);
    stopwatch.stop();

    return AuditResult(
      issues: issues,
      filesScanned: filesScanned,
      duration: stopwatch.elapsed,
      pluginSummaries: summaries,
    );
  }

  /// Orders issues by file path, then position (line, then column, via
  /// [SourceLocation.compareTo]), then rule ID, so that reports are stable
  /// across runs regardless of plugin or filesystem iteration order.
  static int _compareIssues(AuditIssue a, AuditIssue b) {
    var comparison = a.filePath.compareTo(b.filePath);
    if (comparison != 0) return comparison;

    comparison = a.range.start.compareTo(b.range.start);
    if (comparison != 0) return comparison;

    return a.ruleId.compareTo(b.ruleId);
  }
}
