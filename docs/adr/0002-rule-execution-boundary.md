# ADR-0002: Rule Execution Boundary

- Status: Accepted
- Date: 2026-07-12

## Context

ADR-0001 establishes that the core must remain independent of any
programming language or framework, and that language-specific logic lives
entirely inside plugins.

That decision has a direct consequence for how rules are modeled: if the
core defined a generic rule-execution method (for example, an
`execute(input)` contract), it would have to choose a shape for `input` —
a resolved AST, a token stream, a file path, a whole-project graph. Any
such choice either leaks one ecosystem's concepts into the core (an AST
shape is meaningless to a future dependency-health rule that only reads
`pubspec.yaml`) or forces every future ecosystem into an awkward
lowest-common-denominator shape that fits none of them well.

This ADR makes explicit where rule *execution* actually happens, since
ADR-0001 only established that language-specific *logic* belongs to
plugins — it did not specify where the boundary between "the engine's
job" and "a plugin's job" falls with respect to individual rules.

## Decision

The engine orchestrates plugins, not rules.

`AuditEngine` never invokes a rule directly and never iterates over rules.
It invokes exactly one method per registered plugin —
`AuditPlugin.analyze(AuditContext) -> PluginAnalysisResult` — and has no
visibility into how many rules a plugin ran, or how, to produce that
result.

Plugins orchestrate their own rules internally.

A plugin's `analyze()` is responsible for discovering relevant files,
parsing or otherwise inspecting them, running every rule it owns against
that material, and folding the resulting issues into one
`PluginAnalysisResult`. This is entirely the plugin's concern; the engine
does not participate in it and does not need to.

Rule execution mechanics are intentionally private to each plugin.

How a rule actually finds a violation — an AST visitor, a token scanner, a
regular expression, a manifest-file reader — is never expressed in a core
type and never exposed outside the plugin that owns it. Two different
plugins are free to implement "rule execution" in completely unrelated
ways; nothing in the core constrains this.

Core only understands rule identity and metadata.

The core-facing rule contract, `AuditRule`, exposes exactly one member: an
`AuditRuleMetadata` getter (stable ID, name, description, default
severity, category). The core, engine, and reporters never call rule
evaluation; they only ever consume the plain `AuditIssue` values a
plugin's `analyze()` already produced.

Rule IDs are intended to be globally unique and namespaced.

By convention, a rule ID is namespaced as `<plugin>.<category>.<name>`
(for example, `flutter.localization.hardcoded-ui-string`). This is a
naming convention every plugin author is expected to follow, not a
mechanism the core enforces — see Consequences.

Future versions may expand `AuditRule` behavior, but before v1.0 it
intentionally exposes metadata only.

A richer core-level rule contract (for example, a common way to describe
a rule's applicability, or a shared configuration shape) may be justified
once more than one plugin exists and a real, demonstrated need emerges.
Adding such a contract now, before any second plugin exists to validate
its shape, would be exactly the kind of speculative abstraction this
project avoids elsewhere.

## Consequences

Advantages

- A plugin can implement rule execution however best suits its ecosystem,
  without negotiating a shared execution contract with the core or with
  other plugins.
- Adding a rule to an existing plugin, or adding a plugin with a
  completely different execution strategy (per-file vs. whole-project),
  never requires an engine change.
- The core's rule-related public surface (`AuditRule`, `AuditRuleMetadata`,
  `AuditCategory`) stays small and easy to keep stable, since it carries no
  execution semantics that might need to change as ecosystems are added.

Disadvantages

- Rule ID uniqueness is a convention, not an enforced guarantee. Nothing in
  the core prevents two different plugins from claiming the same rule ID.
  This has not mattered with a single plugin; it becomes a real question
  the first time a second plugin is registered alongside the Flutter
  plugin, and is called out here explicitly so it is not discovered by
  accident later.
- Because the core cannot see how a rule executes, it also cannot offer
  any cross-cutting capability that depends on that visibility (for
  example, a shared rule-level timeout, or a generic "explain why this
  rule fired" mechanism) without either building it per-plugin or
  eventually widening the `AuditRule` contract — which this ADR
  deliberately defers.

## Notes

This ADR does not change anything established in ADR-0001; it narrows
"language-specific logic lives in plugins" specifically to rule execution,
and records the reasoning for why `AuditRule` is metadata-only rather than
behavior-bearing as of `0.1.0-dev.1`.
