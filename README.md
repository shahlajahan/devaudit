# DevAudit

> Analyze. Understand. Improve.

A plugin-based developer audit platform for modern software projects.

DevAudit analyzes source code, detects project-specific problems through plugins,
and produces reports designed for both humans and AI coding agents.

Built by **Pharos Labs**.

---

# Why DevAudit?

Traditional linters answer questions like:

- Is this code syntactically correct?
- Does it follow style rules?

DevAudit answers higher-level questions such as:

- Which user-visible strings still aren't localized?
- Which files should be fixed first?
- How can a large audit be split into AI-friendly tasks?
- How can thousands of findings be organized into reports that fit within an AI agent's context window?

Instead of producing a single huge report, DevAudit generates structured report bundles that make large-scale code improvements practical.

---

# Features

Current capabilities include:

- Plugin-based architecture
- Language-agnostic audit engine
- Flutter/Dart localization audit
- Human-readable console reports
- Machine-readable JSON reports
- Multi-file report bundles
- Folder-level summaries
- AI-agent task bundles
- Deterministic output
- Zero Flutter dependency inside the core engine

---

# Example

Given:

```dart
Text("Settings")
Text("Followers")
Text("Save")
```

Run:

```bash
devaudit scan .
```

Output:

```text
lib/profile_page.dart
  9:34  warning  Probable user-visible hardcoded string in Text(data: ...). ('Profile')
 10:36  warning  Probable user-visible hardcoded string in Text(data: ...). ('Followers')
```

Or generate an AI-ready report bundle:

```bash
devaudit scan . \
  --report \
  --report-folders \
  --agent-tasks
```

Result:

```text
devaudit-report/

summary.md
summary.json

files/
folders/

agent/
    manifest.json
    tasks/
```

Each task corresponds to exactly one source file, allowing AI coding agents to process very large projects incrementally without exceeding context limits.

---



# Current Status

**Pre-1.0**

DevAudit is under active development and is not yet published on pub.dev.

Currently implemented:

- Plugin-based audit engine
- Flutter localization plugin
- Console reporter
- JSON reporter
- Report bundles
- Folder reports
- AI-agent task bundles

Future work is tracked in the roadmap.

---

# Installation

Clone the repository:

```bash
git clone https://github.com/shahlajahan/devaudit.git
cd devaudit
dart pub get
```

Run directly:

```bash
dart run bin/devaudit.dart scan .
```

Or activate it globally from a local checkout:

```bash
dart pub global activate --source path .
```

If the executable is not on your PATH:

```bash
export PATH="$HOME/.pub-cache/bin:$PATH"
```

Verify the installation:

```bash
devaudit --version
```

---

# Quick Start

Scan the current project:

```bash
devaudit scan .
```

Scan another project:

```bash
devaudit scan /path/to/project
```

Generate JSON:

```bash
devaudit scan . --format=json
```

Write JSON to disk:

```bash
devaudit scan . \
  --format=json \
  --output=report.json
```

Generate a report bundle:

```bash
devaudit scan . --report
```

Generate the complete bundle:

```bash
devaudit scan . \
  --report \
  --report-folders \
  --agent-tasks
```

---

# CLI Options

| Option | Description |
|----------|-------------|
| `--format` | `console` or `json` |
| `--output` | Write the report to a file |
| `--fail-on` | Exit-code threshold |
| `--min-severity` | Minimum rendered severity |
| `--include` | Additional files/directories |
| `--exclude` | Additional ignored paths |
| `--verbose` | Plugin diagnostics |
| `--report` | Generate report bundle |
| `--report-folders` | Generate folder summaries |
| `--agent-tasks` | Generate AI task bundle |

---

# Report Bundles

Large projects often contain hundreds or thousands of findings.

Instead of producing one enormous report, DevAudit can split results into independently addressable documents.

The generated bundle contains:

- `summary.md`
- `summary.json`
- One Markdown report per source file
- Optional folder reports
- Optional AI-agent task bundles

This enables:

- Incremental review
- Parallel work
- AI-assisted refactoring
- Avoiding LLM context-window limitations

See:

```
docs/reporting/report-bundles.md
```

---

# Architecture

```
CLI
 │
 ▼
Audit Engine
 │
 ▼
Plugins
 │
 ▼
Rules
```

The core engine knows nothing about Flutter, Dart, or localization.

Everything language-specific lives inside plugins.

This allows future plugins for ecosystems such as:

- React
- TypeScript
- Kotlin
- Swift
- Rust

without changing the engine itself.

---

# Flutter Localization Plugin

Current built-in rule:

```
flutter.localization.hardcoded-ui-string
```

Detects probable user-visible hardcoded strings inside common Flutter widgets, including:

- Text
- TextSpan
- Tooltip
- InputDecoration
- Semantics
- BottomNavigationBarItem
- IconButton tooltips
- AppBar titles
- and other common UI APIs

Already-localized strings are automatically ignored.

---

# Suppressing Findings

Suppress a single line:

```dart
Text(
  "Debug",
); // devaudit-ignore: flutter.localization.hardcoded-ui-string
```

Suppress an entire file:

```dart
// devaudit-ignore-file: flutter.localization.hardcoded-ui-string
```

---

# Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Scan completed successfully |
| `1` | Findings reached the configured `--fail-on` threshold |
| `2` | Invalid CLI usage or execution failure |

---

# Documentation

Architecture

```
docs/architecture/
```

Rules

```
docs/rules/
```

Architecture Decision Records

```
docs/adr/
```

Roadmap

```
docs/roadmap/
```

---

# Roadmap

Upcoming work includes:

- Accessibility audits
- Performance audits
- Security audits
- Architecture audits
- Dependency health analysis
- Additional language plugins
- GitHub Actions integration
- IDE integrations
- AI-assisted explanations
- Automatic fixes (`--fix`)

See:

```
docs/roadmap/roadmap.md
```

---

# Contributing

Contributions are welcome.

Contribution guidelines will be published in `CONTRIBUTING.md`.

---

# License

Apache License 2.0

See `LICENSE`.