/// DevAudit
///
/// Copyright (c) Pharos Labs.
/// Licensed under the Apache License, Version 2.0.
library;

import '../model/audit_result.dart';
import 'report_bundle.dart';

/// The public contract for turning an [AuditResult] into a [ReportBundle].
///
/// Like [AuditReporter], a bundle generator is a pure function: no file
/// I/O, no archive creation. Writing documents to disk is the CLI layer's
/// responsibility.
///
/// Since: 0.1.0-dev.1
abstract class ReportBundleGenerator {
  /// Allows subclasses to be `const`.
  const ReportBundleGenerator();

  /// Generates a bundle of documents describing [result], for the scan
  /// target [target] (typically the user-supplied path or project root).
  ReportBundle generate(AuditResult result, {required String target});
}
