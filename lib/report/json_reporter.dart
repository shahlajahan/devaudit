/// DevAudit
///
/// Copyright (c) Pharos Labs.
/// Licensed under the Apache License, Version 2.0.
library;

import 'dart:convert';

import '../core/model/audit_result.dart';
import '../core/report/audit_reporter.dart';

/// The DevAudit version stamped onto every JSON report.
///
/// Kept in sync manually with the `version` field in `pubspec.yaml`.
const toolVersion = '0.1.0-dev.1';

/// Renders an [AuditResult] as deterministic, pretty-printed JSON.
///
/// The output includes a [schemaVersion] so downstream tooling can evolve
/// the report format without breaking existing consumers.
///
/// Since: 0.1.0-dev.1
class JsonReporter extends AuditReporter {
  /// Creates a JSON reporter.
  const JsonReporter();

  /// The version of the JSON report schema this reporter produces.
  static const schemaVersion = '1.0';

  @override
  String render(AuditResult result, {required String target}) {
    // Reporter-owned fields are inserted after the spread so they remain
    // authoritative: a map literal's later keys win on collision, so
    // nothing AuditResult.toJson() ever produces can silently override
    // schemaVersion, tool, or target.
    final report = <String, Object?>{
      ...result.toJson(),
      'schemaVersion': schemaVersion,
      'tool': {'name': 'devaudit', 'version': toolVersion},
      'target': target,
    };

    return const JsonEncoder.withIndent('  ').convert(report);
  }
}
