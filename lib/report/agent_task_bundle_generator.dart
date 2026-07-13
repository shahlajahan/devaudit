/// DevAudit
///
/// Copyright (c) Pharos Labs.
/// Licensed under the Apache License, Version 2.0.
library;

import 'dart:convert';

import 'package:path/path.dart' as p;

import '../core/model/audit_issue.dart';
import '../core/model/audit_result.dart';
import '../core/report/report_bundle.dart';
import '../core/report/report_bundle_generator.dart';
import '../shared/tool_version.dart';
import 'report_bundle_helpers.dart';

const _safetyPreamble =
    'Only make the changes described below. Do not alter unrelated logic, '
    'tests, or formatting.';

/// Generates an AI-agent task bundle: one Markdown task per source file
/// with findings, plus a JSON manifest indexing all of them.
///
/// Output lives under `agent/` (not a hidden directory), per the accepted
/// deviation from the literal `.agent/` path in ADR-0003's original text:
///
/// ```
/// agent/
///   manifest.json
///   tasks/
///     0001_pet_taxi_booking_page.md
///     0002_drawer_menu.md
/// ```
///
/// A task's suggested objective is derived entirely from the distinct
/// [AuditIssue.suggestion] values already present on that file's issues,
/// plus a fixed, generator-owned safety preamble — no new core or
/// rule-level field is needed, and this scales to future rules without
/// this generator needing to become rule-aware.
///
/// Since: 0.1.0-dev.1
class AgentTaskBundleGenerator extends ReportBundleGenerator {
  /// Creates an agent task bundle generator.
  const AgentTaskBundleGenerator();

  /// The version of the `agent/manifest.json` schema this generator
  /// produces, tracked independently from every other JSON schema this
  /// package produces.
  static const schemaVersion = '1.0';

  @override
  ReportBundle generate(AuditResult result, {required String target}) {
    final byFile = groupIssuesBy(result.issues, (issue) => issue.filePath);

    final documents = <ReportDocument>[];
    final manifestTasks = <Map<String, Object?>>[];

    var index = 0;
    for (final entry in byFile.entries) {
      index++;
      final filePath = entry.key;
      final issues = entry.value;
      final taskId = index.toString().padLeft(4, '0');
      final slug = p.posix.basenameWithoutExtension(filePath);
      final taskPath = 'agent/tasks/${taskId}_$slug.md';
      final ruleIds = issues.map((issue) => issue.ruleId).toSet().toList()
        ..sort();

      documents.add(
        ReportDocument(
          path: taskPath,
          content: _renderTask(
            taskId: taskId,
            filePath: filePath,
            issues: issues,
          ),
        ),
      );

      manifestTasks.add({
        'id': taskId,
        'file': filePath,
        'task': taskPath,
        'findingCount': issues.length,
        'ruleIds': ruleIds,
      });
    }

    documents.add(
      ReportDocument(
        path: 'agent/manifest.json',
        content: _renderManifest(target, manifestTasks),
      ),
    );

    return ReportBundle(documents: documents);
  }

  String _renderTask({
    required String taskId,
    required String filePath,
    required List<AuditIssue> issues,
  }) {
    final objectives = issues
        .map((issue) => issue.suggestion)
        .whereType<String>()
        .toSet();

    final buffer = StringBuffer()
      ..writeln('# Task $taskId: $filePath')
      ..writeln()
      ..writeln('## Target file')
      ..writeln()
      ..writeln(filePath)
      ..writeln()
      ..writeln('## Findings')
      ..writeln();

    for (final issue in issues) {
      buffer.writeln(renderIssueBullet(issue));
    }

    buffer
      ..writeln()
      ..writeln('## Suggested objective')
      ..writeln()
      ..writeln(_safetyPreamble);

    for (final objective in objectives) {
      buffer.writeln('- $objective');
    }

    return buffer.toString();
  }

  String _renderManifest(String target, List<Map<String, Object?>> tasks) {
    final json = <String, Object?>{
      'schemaVersion': schemaVersion,
      'tool': {'name': 'devaudit', 'version': toolVersion},
      'target': target,
      'tasks': tasks,
    };
    return const JsonEncoder.withIndent('  ').convert(json);
  }
}
