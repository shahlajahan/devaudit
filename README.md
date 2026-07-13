# DevAudit

> Analyze. Understand. Improve.

A plugin-based developer audit platform for modern software projects, by
[Pharos Labs](https://pharosteknoloji.com.tr).

DevAudit's core is a small, language-agnostic engine: it knows how to run
plugins and combine their findings into one report. It has no idea what
"Flutter" or "Dart" is. All ecosystem-specific knowledge lives in plugins.

---

## Current status

**Pre-1.0, under active development.** The package is not yet published to
pub.dev.

### Implemented today

- A plugin-based core: `AuditEngine`, `AuditPlugin`, `AuditRule`,
  `AuditReporter`, and immutable domain models (`AuditIssue`, `AuditResult`,
  `SourceRange`, `AuditSeverity`, ...).
- One built-in plugin: **Flutter/Dart localization**, which parses Dart
  source with `package:analyzer` and implements a single rule:
  `flutter.localization.hardcoded-ui-string`.
- A `devaudit scan` CLI with console and JSON reporters.

### Not implemented yet

Everything under [Roadmap](docs/roadmap/roadmap.md) beyond the items above:
accessibility/performance/security/architecture audits, dependency health,
React/TypeScript/Kotlin/Swift support, GitHub Actions, IDE integrations, a
`--fix` mode, and AI-assisted explanations. Please don't rely on any of this
existing yet — treat this README as ground truth over the roadmap for what's
actually built.

---

## Installation (development)

DevAudit isn't published yet, so run it from a source checkout:

```bash
git clone https://github.com/shahlajahan/devaudit.git
cd devaudit
dart pub get
```

Run it directly with `dart run`:

```bash
dart run bin/devaudit.dart scan /path/to/your/flutter/project
```

Or activate it globally from the local checkout so the `devaudit` command is
on your `PATH`:

```bash
dart pub global activate --source path .
devaudit scan /path/to/your/flutter/project
```

## CLI quick start

```bash
devaudit scan                       # scan the current directory
devaudit scan .                     # same as above, explicit
devaudit scan /path/to/project      # scan a specific project
devaudit scan . --format=json
devaudit scan . --format=json --output=devaudit-report.json
devaudit scan . --fail-on=warning   # exit 1 if any warning or error is found
devaudit --help
devaudit --version
```

`devaudit scan` defaults to scanning `lib/` under the target directory,
skipping `.dart_tool/`, `build/`, `.git/`, and recognized generated files
(`*.g.dart`, `*.freezed.dart`, `*.gr.dart`, `*.config.dart`, `*.mocks.dart`,
and files carrying a `GENERATED CODE - DO NOT MODIFY BY HAND` header, such as
`flutter gen-l10n` output).

### Exit codes

| Code | Meaning |
| ---- | ------- |
| `0`  | Scan completed and the `--fail-on` threshold was not reached |
| `1`  | Findings reached the configured `--fail-on` threshold |
| `2`  | Invalid CLI usage, or an unrecoverable execution/configuration failure |

### Options

| Option | Default | Description |
| ------ | ------- | ----------- |
| `--format` | `console` | `console` or `json` |
| `--output` | *(stdout)* | Write the report to a file instead of stdout |
| `--fail-on` | `error` | `none`, `warning`, or `error` — the minimum severity that causes exit code `1` |
| `--include` | *(none)* | Additional files/directories to analyze |
| `--exclude` | *(none)* | Additional path substrings to skip |
| `--verbose` | off | Print per-plugin diagnostics to stderr |

## Example console output

```
$ devaudit scan test/fixtures/flutter_localization

DevAudit

lib/positive_cases.dart
  11:34  warning  Probable user-visible hardcoded string in Text(data: ...). ('Settings')  [flutter.localization.hardcoded-ui-string]
  14:16  warning  Probable user-visible hardcoded string in Text(data: ...). ('Hello')  [flutter.localization.hardcoded-ui-string]
  15:16  warning  Probable user-visible hardcoded string in Text(data: ...). ("Save")  [flutter.localization.hardcoded-ui-string]

lib/profile_page.dart
  9:34   warning  Probable user-visible hardcoded string in Text(data: ...). ('Profile')  [flutter.localization.hardcoded-ui-string]
  10:36  warning  Probable user-visible hardcoded string in Text(data: ...). ('Followers')  [flutter.localization.hardcoded-ui-string]
  10:55  warning  Probable user-visible hardcoded string in Text(data: ...). ('Following')  [flutter.localization.hardcoded-ui-string]

Summary
  Files scanned: 6
  Issues: 14
  Info: 0
  Warnings: 14
  Errors: 0
  Duration: 84 ms
```

(Truncated for brevity — the real output lists every finding, grouped by file.)

## Example JSON output

```json
{
  "filesScanned": 6,
  "durationMs": 84,
  "issueCount": 14,
  "infoCount": 0,
  "warningCount": 14,
  "errorCount": 0,
  "pluginSummaries": [{ "pluginId": "flutter", "filesScanned": 6, "succeeded": true }],
  "issues": [
    {
      "ruleId": "flutter.localization.hardcoded-ui-string",
      "severity": "warning",
      "message": "Probable user-visible hardcoded string in Text(data: ...).",
      "filePath": "lib/positive_cases.dart",
      "range": { "startLine": 11, "startColumn": 34, "endLine": 11, "endColumn": 44 },
      "evidence": "'Settings'",
      "suggestion": "Move this text into the project's localization resources instead of hardcoding it."
    }
  ],
  "schemaVersion": "1.0",
  "tool": { "name": "devaudit", "version": "0.1.0-dev.1" },
  "target": "test/fixtures/flutter_localization"
}
```

Paths in every report are project-relative and forward-slashed — never an
absolute, machine-specific path.

---

## Architecture

```
CLI / application layer
        │
        ▼
Core contracts and engine   (no Flutter, no analyzer, no args, no dart:io*)
        ▲
        │ implements
Plugins (e.g. Flutter)
```

The core (`lib/core/`) defines immutable domain models and the
`AuditPlugin` / `AuditRule` / `AuditReporter` contracts, plus the
`AuditEngine` that runs plugins and merges their issues into one
deterministically ordered `AuditResult`. It never imports Flutter,
`package:analyzer`, `package:args`, `package:yaml`, or any plugin or CLI
code. The Flutter/Dart plugin (`lib/plugins/flutter/`) is a normal
consumer of those contracts, not a special case.

See [docs/architecture/overview.md](docs/architecture/overview.md),
[docs/architecture/domain-model.md](docs/architecture/domain-model.md), and
[docs/architecture/audit-flow.md](docs/architecture/audit-flow.md) for more
detail, and [docs/adr/](docs/adr/) for the underlying decision record.

## The localization rule

`flutter.localization.hardcoded-ui-string` looks for probable user-visible
strings hardcoded directly into common Flutter UI APIs (`Text`, `TextSpan`,
`InputDecoration`, `Tooltip`, `Semantics`, and more), while recognizing
common localization patterns (`context.l10n`, `AppLocalizations.of(context)`,
`.tr()`, `S.of(context)`, and similar) so it doesn't flag text that's already
localized. See
[docs/rules/flutter-hardcoded-ui-string.md](docs/rules/flutter-hardcoded-ui-string.md)
for the full list of detected APIs, exclusions, and false-positive
boundaries.

### Suppressing a finding

```dart
Text('Debug label'), // devaudit-ignore: flutter.localization.hardcoded-ui-string
```

or, on the line above the flagged code:

```dart
// devaudit-ignore: flutter.localization.hardcoded-ui-string
Text('Debug label'),
```

To suppress every finding for this rule in an entire file, add this near the
top of the file:

```dart
// devaudit-ignore-file: flutter.localization.hardcoded-ui-string
```

---

## Roadmap

See [docs/roadmap/roadmap.md](docs/roadmap/roadmap.md).

## Contributing

Contributions are welcome. Contribution guidelines will be published in
`CONTRIBUTING.md`.

## License

Apache License 2.0 — see [LICENSE](LICENSE).
