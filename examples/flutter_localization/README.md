# Flutter Localization Example

This example demonstrates the built-in Flutter localization rule included with DevAudit.

It intentionally contains user-visible hardcoded strings so the scanner can detect and report localization issues.

## Prerequisites

```bash
flutter pub get
```

## Scan the project

```bash
devaudit scan project
```

## Generate a complete report bundle

```bash
devaudit scan project \
  --report \
  --report-folders \
  --agent-tasks
```

## Expected results

- 6 Dart files scanned
- 14 localization warnings
- Console report
- JSON report
- Markdown report bundle
- AI agent task bundle

## Project structure

```
project/
├── lib/
│   ├── positive_cases.dart
│   ├── negative_cases.dart
│   ├── profile_page.dart
│   ├── suppressed_file.dart
│   └── suppressed_line.dart
```

## Tested with

- Flutter 3.38.5
- Dart 3.10.4