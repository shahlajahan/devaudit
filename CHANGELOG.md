# Changelog

## Unreleased

Initial MVP of DevAudit: a plugin-based core engine, a Flutter/Dart
localization plugin, console and JSON reporters, and a `devaudit scan` CLI.
Not yet published to pub.dev.

### Added

- Core domain model (`lib/core/model/`): `AuditSeverity`, `SourceLocation`,
  `SourceRange`, `AuditIssue`, `AuditContext`, `AuditResult`, and
  `PluginExecutionSummary`. All are immutable, with manual `==`/`hashCode`
  and deterministic `toJson()` (no code generation).
- Core contracts (`lib/core/plugin/`, `lib/core/rule/`,
  `lib/core/report/`): `AuditPlugin`, `AuditRule`, `AuditRuleMetadata`,
  `AuditCategory`, and `AuditReporter`.
- `AuditEngine` (`lib/core/engine/`): runs registered plugins, merges their
  issues into one deterministically ordered `AuditResult` (sorted by file
  path, then line, then column, then rule ID), and records a per-plugin
  failure without aborting the rest of the audit.
- `FlutterAuditPlugin` (`lib/plugins/flutter/`): the first concrete plugin.
  Discovers Dart files under `lib/` (skipping `.dart_tool/`, `build/`,
  `.git/`, known generated-file suffixes, and generated-file content
  headers; never following symlinks), parses them with `package:analyzer`,
  and runs `HardcodedUiStringRule` against the resulting AST.
- `flutter.localization.hardcoded-ui-string` rule: detects probable
  user-visible strings hardcoded into `Text`, `TextSpan`,
  `InputDecoration`, `Tooltip`, `Semantics`, `BottomNavigationBarItem`,
  `NavigationDestination`, `IconButton`, `FloatingActionButton`, and `Tab`,
  while recognizing common localization patterns
  (`AppLocalizations.of(context)`, `S.of(context)`, `context.l10n`,
  `.tr()`, `.translate()`, `Intl.message(...)`) so it doesn't flag already
  localized text. Supports line-level and file-level suppression comments
  (`// devaudit-ignore: <rule-id>`, `// devaudit-ignore-file: <rule-id>`).
  See `docs/rules/flutter-hardcoded-ui-string.md`.
- `ConsoleReporter` and `JsonReporter` (`lib/report/`): human-readable,
  file-grouped console output, and deterministic, schema-versioned
  (`schemaVersion: "1.0"`), pretty-printed JSON. Neither reporter emits
  absolute, machine-specific paths.
- `devaudit scan [target]` CLI (`lib/cli/`, `bin/devaudit.dart`), built on
  `package:args`: `--format`, `--output`, `--fail-on`, `--include`,
  `--exclude`, `--verbose`, `--help`, `--version`. Exit codes: `0` (clean),
  `1` (findings reached the `--fail-on` threshold), `2` (invalid usage or
  an unrecoverable execution failure). Invalid input never prints a raw
  stack trace.
- Architecture documentation: `docs/architecture/overview.md`,
  `docs/architecture/domain-model.md`, `docs/architecture/audit-flow.md`.
- Test suite covering core serialization/sorting/aggregation, the
  localization rule's positive/negative/suppression fixtures, both
  reporters, and CLI exit-code behavior.

### Changed

- `pubspec.yaml`: package version set to `0.1.0-dev.1`; added `analyzer`,
  `args`, `collection`, `meta`, and `path` as runtime dependencies; added
  `homepage`, `repository`, and `issue_tracker`.
- `analysis_options.yaml`: enabled `public_member_api_docs`,
  `prefer_single_quotes`, and `unnecessary_lambdas` on top of
  `package:lints/recommended.yaml`; excluded `test/fixtures/**` (those
  files intentionally reference Flutter APIs without a Flutter SDK
  dependency, and are parsed by tests rather than analyzed).
- `README.md`: rewritten to distinguish implemented functionality from the
  roadmap, with real (not invented) console and JSON output samples.
