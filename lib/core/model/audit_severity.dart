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
