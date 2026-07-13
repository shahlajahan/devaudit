/// DevAudit
///
/// Copyright (c) Pharos Labs.
/// Licensed under the Apache License, Version 2.0.
library;

/// Defines the severity level of an [AuditIssue].
///
/// Severity communicates how important a finding is and allows reporters,
/// CI pipelines, IDE integrations, and other consumers to determine the
/// appropriate response.
///
/// This enum belongs to the Core Domain Model and therefore must remain
/// independent from any programming language, framework, or plugin.
///
/// Since: 0.1.0-dev.1
enum AuditSeverity {
  /// Informational finding.
  ///
  /// Indicates useful information that does not require user action.
  info,

  /// Warning finding.
  ///
  /// Indicates a potential issue that should be reviewed but does not
  /// necessarily represent an incorrect implementation.
  warning,

  /// Error finding.
  ///
  /// Indicates a rule violation that should be addressed.
  error,
}

/// An explicit, closed-set ranking of [AuditSeverity] values, from least to
/// most severe.
///
/// This is deliberately introduced only now that a real feature (minimum-
/// severity filtering, `devaudit scan --min-severity`) needs to compare
/// severities. It is a `switch` over every value rather than a reuse of
/// enum declaration order, so that adding a future severity forces a
/// compile error here until its rank is assigned intentionally.
extension AuditSeverityRanking on AuditSeverity {
  /// This severity's rank; a higher number means more severe.
  int get rank => switch (this) {
    AuditSeverity.info => 0,
    AuditSeverity.warning => 1,
    AuditSeverity.error => 2,
  };
}
