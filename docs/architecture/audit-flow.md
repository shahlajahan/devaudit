# Audit Flow

This is the sequence of a single `devaudit scan` run, from the CLI down to
the rendered report.

```mermaid
sequenceDiagram
    participant User
    participant CLI as ScanCommand
    participant Engine as AuditEngine
    participant Plugin as FlutterAuditPlugin
    participant Discovery as FlutterFileDiscovery
    participant Analyzer as DartFileAnalyzer
    participant Rule as HardcodedUiStringRule
    participant Reporter as ConsoleReporter / JsonReporter

    User->>CLI: devaudit scan [target] --format --fail-on
    CLI->>CLI: validate target directory exists
    CLI->>Engine: run(AuditContext(projectRoot, include, exclude))
    Engine->>Plugin: analyze(context)
    Plugin->>Discovery: discover(projectRoot)
    Discovery-->>Plugin: sorted List<File> (lib/, minus excluded/generated)
    loop each file
        Plugin->>Plugin: read file, skip if unreadable or generated
        Plugin->>Analyzer: parse(path, content)
        Analyzer-->>Plugin: ParseStringResult (unit, lineInfo, errors)
        alt syntax errors present
            Plugin->>Plugin: skip file, keep scanning
        else
            Plugin->>Rule: evaluate(relativePath, source, unit, lineInfo)
            Rule-->>Plugin: List<AuditIssue>
        end
    end
    Plugin-->>Engine: PluginAnalysisResult(issues, filesScanned)
    Engine->>Engine: merge issues, sort by file/line/column/ruleId
    Engine-->>CLI: AuditResult
    CLI->>Reporter: render(result, target)
    Reporter-->>CLI: report String
    CLI->>User: write to stdout or --output file
    CLI->>User: exit code (0, 1, or 2)
```

## Failure handling

- **A single file fails to parse or read**: the plugin skips it and keeps
  scanning the rest of the project. It is still counted in `filesScanned`
  once reading succeeds, even if parsing then fails.
- **A whole plugin throws**: `AuditEngine.run` catches the exception,
  records it in `AuditResult.pluginSummaries` (with `succeeded: false` and
  the error message), and continues with any remaining plugins. A plugin
  failure never aborts the audit or crashes the CLI.
- **Invalid CLI usage** (bad `--format` value, wrong number of arguments,
  missing target directory): the CLI returns exit code `2` with a short,
  human-readable message on stderr — never a raw stack trace.

## Determinism

`AuditEngine` sorts the combined issue list by file path, then line, then
column, then rule ID before returning it, regardless of plugin iteration
order or filesystem traversal order. Both reporters render from that same
sorted list, so console and JSON output are stable across repeated runs on
an unchanged project.
