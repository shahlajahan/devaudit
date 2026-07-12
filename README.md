# DevAudit

> Analyze. Understand. Improve.

A plugin-based developer audit platform for modern software projects.

DevAudit helps developers identify code quality issues, explain why they matter,
and guide teams toward more maintainable, secure, and consistent software.

---

## Vision

Modern software quality is much more than linting.

DevAudit aims to provide a unified auditing platform capable of analyzing
different programming languages, frameworks, and project structures through a
plugin-based architecture.

The first supported platform is Flutter, but the architecture is designed to
support many additional ecosystems.

---

## Planned Audit Categories

- Localization
- Accessibility
- Performance
- Security
- Architecture
- Best Practices
- Maintainability
- Documentation
- Dependency Health

---

## Planned Language Support

- Flutter / Dart
- React
- TypeScript
- Kotlin
- Swift
- Python
- Go

---

## Architecture

DevAudit is built around a plugin-based architecture.

The application core never contains language-specific logic.

Every supported ecosystem is implemented as an independent plugin.

See:

- docs/adr/
- docs/architecture/

---

## Current Status

Current development stage:

**Pre-Alpha**

The first milestone focuses on building the project foundation and the Flutter
Localization Audit plugin.

---

## Roadmap

### Phase 1

- Project Foundation
- CLI
- Plugin System

### Phase 2

Flutter Plugin

- Localization
- Hardcoded String Detection

### Phase 3

Accessibility Rules

### Phase 4

Performance Rules

### Phase 5

Security Rules

---

## Contributing

Contributions are welcome.

Contribution guidelines will be available in
CONTRIBUTING.md.

---

## License

Apache License 2.0

See LICENSE.