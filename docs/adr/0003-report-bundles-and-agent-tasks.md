# ADR-0003: Report Bundles and Agent Task Output

- Status: Accepted and implemented (Phase 1)
- Date: 2026-07-13

## Context

`AuditReporter` (`String render(AuditResult, {required target})`) is a pure,
single-document contract: one string, written to stdout or one `--output`
file. That is correct for CI and quick human checks, but it does not scale
to real projects. On a project with 442 files and 1,273 findings, a single
console or JSON report exceeds both practical terminal/history limits and
the context window of any AI coding agent (Claude Code, Codex, ChatGPT,
Gemini, Cursor, and similar tools) — no such report can be consumed in one
prompt.

The scanning engine is not the problem and is out of scope for this ADR.
The output layer needs a second, additive mode: many small,
independently-addressable documents instead of one large one, structured
so a human can see totals and hotspots immediately, and so an AI agent can
process one file's findings at a time.

## Decision

### `ReportBundle` is a new, additive core contract — `AuditReporter` is unchanged

`AuditReporter` stays exactly as-is; it is already stable, exported, and
correct for its use case. Widening it to produce multiple documents would
be a breaking change to existing public API for no benefit to the
console/JSON use case. Instead, a parallel contract is introduced in
`core/report/`, the same layer `AuditReporter` already lives in:

```dart
final class ReportDocument {
  const ReportDocument({required this.path, required this.content});
  /// Forward-slash relative path within the bundle, e.g.
  /// 'files/lib/ui/vet_page.dart.md'.
  final String path;
  final String content;
}

final class ReportBundle {
  ReportBundle({required List<ReportDocument> documents})
      : documents = List.unmodifiable(documents);
  final List<ReportDocument> documents;
}

abstract class ReportBundleGenerator {
  const ReportBundleGenerator();
  /// Pure function: no file I/O, no zip creation. Writing documents to
  /// disk, or packaging them into an archive, is the CLI layer's job —
  /// the same separation of concerns AuditReporter already documents.
  ReportBundle generate(AuditResult result, {required String target});
}
```

`ReportBundle` is a plain, immutable snapshot (`List.unmodifiable`, same
defensive-copy pattern as `AuditResult`). It has **no public `merge()`
method** — combining bundles produced by different generators is a CLI
concern, not a core one, and a public merge that silently concatenates
documents would hide path collisions between generators. Combining happens
in an internal `ReportBundleComposer` (CLI-layer, not exported) that
explicitly checks for duplicate `path` values across the bundles it
combines and fails with a clear error (the existing
`executionErrorExitCode`) rather than silently letting one document
overwrite another.

Four concrete generators live in `lib/report/`, alongside
`ConsoleReporter`/`JsonReporter` — nothing here is Flutter-specific, so
nothing belongs under `lib/plugins/flutter/`:

- `SummaryBundleGenerator` → `summary.md`, `summary.json`
- `PerFileMarkdownBundleGenerator` → `files/**/*.md`
- `FolderMarkdownBundleGenerator` → `folders/**/*.md`
- `AgentTaskBundleGenerator` → `agent/manifest.json`, `agent/tasks/*.md`
  (visible directory, not hidden — this is a deliberate implementation-time
  deviation from an earlier draft of this ADR, which specified a hidden
  `.agent/` directory; a visible directory is easier to discover and lists
  cleanly in ordinary directory listings, which matters more here than the
  convention hidden dot-directories usually signal)

No change to `lib/core/model/`, `lib/core/rule/`, `lib/core/plugin/`,
`lib/core/engine/`, or `lib/plugins/flutter/` is required. In particular,
the agent task's "suggested objective" is derived from the distinct
`AuditIssue.suggestion` values already present on a file's issues, plus a
fixed, generator-owned safety preamble ("only make the changes described
below; do not alter unrelated logic, tests, or formatting") — no new
rule-level field is needed, and the design scales to future rules without
the generator becoming rule-aware.

### Report paths mirror the source tree — never flattened

A per-file report's path is the source file's relative path with `.md`
appended to the full filename (including its own extension):

```
files/lib/ui/pet_taxi/pet_taxi_booking_page.dart.md
```

not a flattened `lib_ui_pet_taxi_booking_page.md`. Mirroring the source
tree makes collisions structurally impossible (two source files never
share a path), makes the report's location immediately obvious from the
source path alone, and keeps generated Markdown links between
`summary.md` and `files/**` predictable. Folder reports follow the same
rule: `folders/lib/ui/pet_taxi.md` for the folder `lib/ui/pet_taxi/`.

### CLI surface

```
devaudit scan . --report
devaudit scan . --report --report-dir=reports/devaudit
devaudit scan . --report --report-folders
devaudit scan . --report --agent-tasks
```

- `--report` is the single on-switch; it alone produces
  `summary.md` + `summary.json` + `files/**` in `./devaudit-report/`
  (default) or `--report-dir=<path>`.
- `--report-folders` and `--agent-tasks` are additive flags that each
  **require `--report`** — a usage error (exit code 2) otherwise. This
  intentionally forgoes an agent-only mode (task files without the
  human-facing bundle) to keep the CLI to one primary mode plus additive
  extensions, rather than a matrix of independent toggles. The cost is
  small (extra file writes an agent-only consumer won't read); revisit
  only if a real agent-only use case demonstrates the need — this is not
  something to design speculative flexibility around today.
- `--report-dir` requires `--report` for the same reason; it is
  independent of, and never confused with, the existing `--output` option
  (a single file path for the traditional `--format=console|json` mode).
- All of `--report`/`--report-folders`/`--agent-tasks` are fully
  orthogonal to `--format`/`--output` (both modes can run from one
  invocation) and to `--min-severity` (every bundle generator receives the
  same, possibly-filtered `AuditResult` the existing reporters already
  do) and to `--fail-on` (which always evaluates the original, unfiltered
  result, regardless of which output modes are active — a direct
  carry-over of the invariant established for `--min-severity`).

### Output-directory ownership

Writing hundreds of loose files into a user-specified directory on every
run risks two failure modes: silently deleting something that isn't
DevAudit's to delete, and leaving stale reports behind for files whose
findings have since been fixed. Both are addressed with a marker file,
`.devaudit-report`, written into the report directory on first successful
write, with this exact state machine:

| Directory state | Behavior |
| --- | --- |
| Does not exist | Create it. |
| Exists, empty, no marker | Safe to use — nothing to lose. Proceed and write the marker. |
| Exists, contains the marker | DevAudit owns it — clear its previously-generated contents and rebuild. |
| Exists, non-empty, no marker | Refuse. Exit code 2. Never guess whether a non-empty, unmarked directory is safe to touch. |

DevAudit must never recursively delete a directory it cannot prove
ownership of. This state machine must be covered by dedicated tests for
all four cases before this feature ships.

### `summary.json` is its own schema, independently versioned

```json
{
  "schemaVersion": "1.0",
  "tool": { "name": "devaudit", "version": "0.1.0-dev.1" },
  "target": "...",
  "summary": { "filesScanned": 442, "issues": 1273 },
  "bySeverity": {},
  "byRule": {},
  "byFolder": [],
  "byFile": []
}
```

`bySeverity`/`byRule` are objects (key → count); `byFolder`/`byFile` are
arrays, since those are hotspot lists meant to be read in sorted order,
and array order is the natural way to express "sorted by count
descending" — a JSON object's key order is not a reliable place to encode
that. This schema starts at `"1.0"` but is tracked as an independent
schema family from `JsonReporter`'s existing `schemaVersion: "1.0"` — the
two documents have unrelated shapes, and a future breaking change to one
must not force a version bump on the other just because they happened to
start at the same number.

### ZIP export is deferred, not part of Phase 1

Loose files are the primary deliverable for Phase 1. ZIP packaging
(`--zip`, a future `package:archive` dependency) is deferred: most named
AI coding agents operate by direct filesystem access, so loose files are
arguably *more* consumable for this feature's stated primary audience than
a zip requiring an extraction step some agent sandboxes may not permit.
ZIP remains a plausible Phase 2 addition — a CLI-layer, post-processing
step over an already-generated `ReportBundle`, per the same
no-I/O-in-generators principle as everything else here — but is out of
scope until a real need is demonstrated.

## Consequences

Advantages

- No change to `core/model`, `core/rule`, `core/plugin`, `core/engine`, or
  the Flutter plugin — this is entirely additive at the `core/report/`,
  `lib/report/`, and `lib/cli/` layers.
- `ReportBundleGenerator` generalizes cleanly to future formats (SARIF,
  an HTML dashboard, GitHub PR review comments) without further core
  change, validating that the abstraction is sized correctly.
- Mirrored, non-flattened paths eliminate an entire class of naming
  collisions by construction, rather than requiring collision-detection
  logic in the per-file generator.
- The marker-file rule makes repeated `devaudit scan --report` runs safe
  and idempotent without ever risking user data outside DevAudit's own
  output directory.

Disadvantages

- `--agent-tasks` requiring `--report` means an agent-only workflow always
  also generates the human-facing bundle, even if unused.
- Two independently-versioned JSON schemas (`JsonReporter` and
  `summary.json`) started at the same version number, which is a minor,
  self-inflicted source of potential confusion if not documented clearly
  at each call site.
- Deferring ZIP means there is, for now, no single-file artifact to
  attach to a PR comment or ticket; a user who wants that must zip the
  output directory themselves.

## Notes

This ADR does not change anything established in ADR-0001 or ADR-0002:
core remains ecosystem-agnostic, and rule execution mechanics remain
plugin-private. It only extends the *output* layer with a second,
multi-document contract alongside the existing single-document one.
