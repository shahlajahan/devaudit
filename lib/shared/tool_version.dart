/// DevAudit
///
/// Copyright (c) Pharos Labs.
/// Licensed under the Apache License, Version 2.0.
library;

/// The current DevAudit package version.
///
/// This is the single source of truth for every place the tool's version
/// is surfaced: `devaudit --version`, [JsonReporter]'s `tool.version`
/// field, and the `tool.version` field in `summary.json` and
/// `agent/manifest.json`. Nothing else in the package may declare its own
/// copy of this value.
///
/// This must be kept in sync manually with the `version` field in
/// `pubspec.yaml` — reading `pubspec.yaml` at runtime is intentionally out
/// of scope for now.
const toolVersion = '0.1.0-dev.2';
