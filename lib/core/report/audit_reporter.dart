/// DevAudit
///
/// Copyright (c) Pharos Labs.
/// Licensed under the Apache License, Version 2.0.
library;

import '../model/audit_result.dart';

/// The public contract for turning an [AuditResult] into a rendered report.
///
/// A reporter is a pure function of an [AuditResult] and a target label to
/// [String]; it must not perform file I/O itself. Writing the rendered
/// report to stdout or a file is the responsibility of the CLI layer.
///
/// Since: 0.1.0-dev.1
abstract class AuditReporter {
  /// Allows subclasses to be `const`.
  const AuditReporter();

  /// Renders [result] for the scan target [target] (typically the
  /// user-supplied path or project root) into a report string.
  String render(AuditResult result, {required String target});
}
