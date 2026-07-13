# Report Bundles

`devaudit scan --report` generates a multi-file report bundle instead of
(or alongside) the traditional single-document `--format=console|json`
report. This exists because a single report — human or JSON — does not
scale: on a real project with hundreds of files and over a thousand
findings, one report exceeds practical terminal/history limits and the
context window of any AI coding agent. A bundle of small,
independently-addressable documents does not have that problem.

See [ADR-0003](../adr/0003-report-bundles-and-agent-tasks.md) for the full
design rationale.

## Quick start

```bash
devaudit scan . --report
```

writes, under `./devaudit-report/` by default:

```
devaudit-report/
├── .devaudit-report
├── summary.md
├── summary.json
└── files/
    └── ... one Markdown file per source file with findings,
            mirroring the source tree exactly
```

## Options

| Option | Default | Description |
| --- | --- | --- |
| `--report` | off | Generate the report bundle (`summary.md`, `summary.json`, `files/**`). |
| `--report-dir` | `devaudit-report` | Where to write the bundle. Requires `--report`. |
| `--report-folders` | off | Additionally generate folder-grouped reports (`folders/**`). Requires `--report`. |
| `--agent-tasks` | off | Additionally generate an AI-agent task bundle (`agent/`). Requires `--report`. |

```bash
devaudit scan . --report
devaudit scan . --report --report-dir=reports/devaudit
devaudit scan . --report --report-folders
devaudit scan . --report --agent-tasks
devaudit scan . --report --report-folders --agent-tasks
```

`--report-folders`, `--agent-tasks`, and `--report-dir` are additive to
`--report` and each require it — passing any of them without `--report` is
a usage error (exit code `2`). This keeps the CLI to one primary mode
(`--report`) plus additive extensions, rather than a matrix of
independent, agent-only or folder-only modes.

`--report` is fully independent of `--format`/`--output`: a single
invocation can produce both, e.g.
`devaudit scan . --format=json --output=ci-report.json --report`.
It is also independent of `--fail-on`, which always evaluates the full,
unfiltered scan — hiding every issue from the bundle via
`--min-severity=error` never changes CI exit-code behavior. `--min-severity`
*does* filter which issues appear in the bundle, exactly as it filters the
traditional report.

## Directory layout — mirrored, not flattened

A per-file report's path is the source file's relative path with `.md`
appended to the full filename (including its own extension):

```
Source: lib/ui/pet_taxi/pet_taxi_booking_page.dart
Report: files/lib/ui/pet_taxi/pet_taxi_booking_page.dart.md
```

Folder reports (`--report-folders`) follow the same rule, one document per
folder that has findings:

```
folders/lib/ui/pet_taxi.md
```

Mirroring the source tree, rather than flattening it into one name (e.g.
`lib_ui_pet_taxi_booking_page.md`), makes path collisions structurally
impossible (two source files never share a path) and keeps a report's
source location obvious from its own path.

A file or folder with no findings gets no document — only actionable
files/folders are represented.

## `summary.md` / `summary.json`

The at-a-glance view of a scan: totals, a breakdown by severity and rule,
and hotspot tables of findings per folder and per file (sorted descending
by count), each linking to the corresponding `files/**`/`folders/**`
document.

`summary.json` schema:

```json
{
  "schemaVersion": "1.0",
  "tool": { "name": "devaudit", "version": "0.1.0-dev.1" },
  "target": "...",
  "summary": { "filesScanned": 442, "issues": 1273 },
  "bySeverity": { "info": 0, "warning": 1273, "error": 0 },
  "byRule": { "flutter.localization.hardcoded-ui-string": 1273 },
  "byFolder": [{ "path": "lib/ui/pet_taxi", "count": 42 }],
  "byFile": [{ "path": "lib/ui/pet_taxi/pet_taxi_booking_page.dart", "count": 12 }]
}
```

`byFolder`/`byFile` are arrays (not objects) specifically because they are
hotspot lists meant to be read in sorted order — array order naturally
expresses "sorted by count descending," which a JSON object's key order
does not reliably convey.

This schema is versioned independently from `JsonReporter`'s
`schemaVersion` (used by `--format=json`): the two documents have
unrelated shapes, and a breaking change to one must not force a version
bump on the other, even though both currently start at `"1.0"`.

## Agent tasks (`--agent-tasks`)

```
agent/
├── manifest.json
└── tasks/
    ├── 0001_pet_taxi_booking_page.md
    └── 0002_drawer_menu.md
```

Note: this lives under a visible `agent/` directory, not a hidden
`.agent/` — easier to discover and lists cleanly in ordinary directory
listings.

One task per source file with findings, numbered `0001`, `0002`, ... in
the engine's deterministic file order (stable and reproducible across
runs). Each task lists its target file, every finding (rule ID, location,
evidence), and a suggested objective: a fixed safety preamble ("only make
the changes described below; do not alter unrelated logic, tests, or
formatting") plus the distinct `AuditIssue.suggestion` values already
present on that file's issues — no separate, rule-specific "objective"
field exists or is needed; this scales to future rules without the
generator becoming rule-aware.

`agent/manifest.json` indexes every task (id, target file, task document
path, finding count, rule IDs), so an orchestrating agent can plan without
opening every task file first.

## Output directory safety

Repeatedly writing hundreds of files into a directory risks two failure
modes: deleting something that isn't DevAudit's to delete, and leaving
stale reports behind for files whose findings have since been fixed. Both
are addressed with a `.devaudit-report` marker file:

| Directory state | Behavior |
| --- | --- |
| Does not exist | Created. |
| Exists, empty (marker or not) | Used freely — nothing to lose. |
| Exists, contains the marker | Cleared and rebuilt from scratch — no stale documents survive. |
| Exists, non-empty, no marker | Refused outright. Exit code `2`. Never touched. |

DevAudit never recursively deletes a directory it cannot prove it owns.

## Known limitations

- No ZIP export in this release. Most AI coding agents named as this
  feature's primary audience (Claude Code, Cursor, and similar tools)
  operate by direct filesystem access, so loose files are arguably more
  consumable than an archive requiring an extraction step some agent
  sandboxes may not permit. See ADR-0003 for the full trade-off
  discussion; this may be revisited if a real need is demonstrated.
- `--agent-tasks` always requires `--report`, so an agent-only workflow
  currently also generates the human-facing bundle even if it goes
  unread.
