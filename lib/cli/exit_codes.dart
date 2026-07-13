/// DevAudit
///
/// Copyright (c) Pharos Labs.
/// Licensed under the Apache License, Version 2.0.
library;

/// Exit code returned when a scan's findings reached the configured
/// `--fail-on` threshold.
const failThresholdExitCode = 1;

/// Exit code returned for invalid CLI usage, or an unrecoverable execution
/// or configuration failure (for example, a missing scan target).
///
/// This is a CLI-wide contract, not specific to any one command, so it
/// lives here rather than inside a particular command's file.
const executionErrorExitCode = 2;
