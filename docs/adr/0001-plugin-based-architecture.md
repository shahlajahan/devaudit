# ADR-0001: Plugin-Based Architecture

- Status: Accepted
- Date: 2026-07-12

## Context

DevAudit is designed as a general-purpose source code auditing framework.

Although the first supported platform is Flutter/Dart, the project is intended
to support additional languages and frameworks in the future, including but not
limited to:

- React
- TypeScript
- Kotlin
- Swift
- Python
- Go

The core engine must remain independent from any programming language or UI
framework.

## Decision

DevAudit adopts a plugin-based architecture.

The application core is responsible only for:

- Project discovery
- Plugin loading
- Rule execution
- Reporting
- CLI

Language-specific logic must never exist inside the core.

Instead, every supported language is implemented as a plugin.

Example:

```
Core
 ├── CLI
 ├── Rule Engine
 ├── Reporter
 └── Plugin Manager
          │
          ├── Flutter Plugin
          ├── React Plugin
          ├── Kotlin Plugin
          └── Swift Plugin
```

Each plugin is responsible for:

- File discovery
- Parsing
- AST visitors
- Rule registration
- Language-specific reporting

## Consequences

Advantages

- Extensible
- Testable
- Independent of Flutter
- Easier maintenance
- Third-party plugins become possible

Disadvantages

- Slightly higher initial complexity
- Plugin API must remain stable

## Notes

Localization is **not** a project.

Localization is only the first audit rule implemented by the Flutter plugin.

Future audit categories include:

- Localization
- Accessibility
- Performance
- Security
- Architecture
- Best Practices