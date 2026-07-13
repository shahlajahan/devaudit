# `flutter.localization.hardcoded-ui-string`

| | |
| --- | --- |
| Plugin | Flutter (`lib/plugins/flutter/`) |
| Category | `localization` |
| Default severity | `warning` |
| Since | `0.1.0-dev.1` |

Detects probable user-visible strings hardcoded directly into common
Flutter UI widgets, instead of being sourced from the project's
localization resources.

## How detection works

The rule parses each Dart file with `package:analyzer` (syntactic parsing
only — no `flutter pub get` or resolved type information required) and
walks the AST looking for calls to a fixed set of well-known Flutter APIs.
It only flags an argument when it is a **bare string literal or
interpolation** — a `MethodInvocation` (such as `.tr()`), a property chain
(such as `context.l10n.save`), or any other expression shape is left alone.
That single rule is what lets the detector recognize common localization
patterns without special-casing each one: none of them are themselves
literal nodes.

### Detected APIs

| Widget / class | Argument(s) checked |
| --- | --- |
| `Text(...)`, `const Text(...)` | first positional argument (`data`) |
| `TextSpan(...)` | `text` |
| `InputDecoration(...)` | `labelText`, `hintText`, `helperText`, `errorText`, `prefixText`, `suffixText`, `counterText`, `semanticCounterText` |
| `Tooltip(...)` | `message` |
| `Semantics(...)` | `label`, `hint`, `value`, `increasedValue`, `decreasedValue` |
| `BottomNavigationBarItem(...)` | `label` |
| `NavigationDestination(...)` | `label` |
| `IconButton(...)` | `tooltip` |
| `FloatingActionButton(...)` | `tooltip` |
| `Tab(...)` | `text` |

Widgets not in this table — `AppBar.title`, `ListTile.title`/`subtitle`,
`SnackBar.content`, `AlertDialog.title`/`content`, `Chip`/`ActionChip`/
`ChoiceChip`/`FilterChip`/`InputChip.label`, `PopupMenuItem`/
`DropdownMenuItem.child`, `NavigationRailDestination.label`,
`MaterialBanner.content`/`actions`, button `child`, and `Text.rich`'s
nested `TextSpan` — are **not special-cased**. They take a `Widget`, and in
practice that widget is a nested `Text(...)` or `TextSpan(...)`, which the
visitor reaches naturally while walking the whole file. This is
deliberate: adding a bespoke check for every widget that can contain a
`Text` would duplicate the same logic dozens of times for no extra
precision.

### Supported literal shapes

- Single- and double-quoted strings: `'Save'`, `"Save"`
- Multiline string literals
- Adjacent string literals (`'foo' 'bar'`), when every part is a plain
  literal
- Simple interpolation, e.g. `Text('Hello $name')` — reported with the full
  source expression as evidence; DevAudit does not pretend to know the
  runtime value of `$name`

## What it ignores

An argument is not reported if, after trimming, it:

- is empty or whitespace-only
- contains no letters at all (numeric-only, punctuation-only, or
  symbol-only strings)
- looks like a URI or URI scheme (`https://...`, `package:...`)
- looks like a route name (`/profile`, `/home/settings`)
- looks like a dotted lookup key (`common.save`, `errors.network.timeout`)
- looks like an asset, image, or font path (`assets/...`, or ending in
  `.png`, `.jpg`, `.svg`, `.ttf`, and similar)

It also never fires on an argument that is *not* a bare literal, which is
what makes it recognize (without listing them one by one):

- `AppLocalizations.of(context)` / `AppLocalizations.of(context)!.save`
- `S.of(context).save`
- `context.l10n.save`, `context.localization.save`
- `LocaleKeys.someKey.tr()`, `'common.save'.tr()`, any `.tr()` / `.translate()`
- `Intl.message(...)`
- `debugPrint(...)`, `print(...)` (these aren't in the detected-API table)
- `map['title']`, enum values, JSON/map keys (again, not in the table)

## Suppressing a finding

```dart
Text('Debug label'), // devaudit-ignore: flutter.localization.hardcoded-ui-string
```

or, as a leading comment on the line above:

```dart
// devaudit-ignore: flutter.localization.hardcoded-ui-string
Text('Debug label'),
```

Suppression is line-based, not tied to Dart statement boundaries — most
widgets are expressions deeply nested in one `return` statement, so
tying suppression to statements would make it useless for anything but the
outermost call. A suppression comment is honored if it appears on the same
line as the literal, the line directly above it, or the line where the
enclosing call's closing parenthesis lands (so it survives `dart format`
wrapping a long call across multiple lines).

To suppress every finding for this rule in an entire file, add this
anywhere in the file (conventionally near the top):

```dart
// devaudit-ignore-file: flutter.localization.hardcoded-ui-string
```

## Excluded files

This rule never scans:

- anything outside `lib/` (unless explicitly passed via `--include`)
- `.dart_tool/`, `build/`, `.git/`
- files ending in `.g.dart`, `.freezed.dart`, `.gr.dart`, `.config.dart`, or
  `.mocks.dart`
- files whose content starts with a `GENERATED CODE - DO NOT MODIFY BY
  HAND` header (this covers `flutter gen-l10n` output, which doesn't use a
  `.g.dart` suffix)
- symlinked files or directories (symlinks are never followed)

## Known limitations / false-positive boundaries

- Detection is **syntactic, not type-resolved**. A local class that happens
  to be named `Text` with a `message:` parameter named `tooltip` would
  match the same heuristic as the real `Tooltip` widget. In practice this
  is rare because the check requires both the exact class name and the
  exact parameter name from the table above.
- A bare, unprefixed call such as `Text('Save')` is indistinguishable at
  the syntax level from a call to a same-named top-level function; DevAudit
  treats any call to one of the known widget names as a match. Renaming a
  local widget-like class to collide with a table entry is the only way to
  trigger a false positive this way, which is an acceptable trade-off for
  not requiring a resolved analysis context.
- Content-based generated-file detection only recognizes the standard
  `GENERATED CODE - DO NOT MODIFY BY HAND` header. A generated file that
  omits this header will be scanned like any other source file.
- Suppression matching does not distinguish a `//` line comment from a
  `///` doc comment, for either suppression directive
  (`devaudit-ignore:` or `devaudit-ignore-file:`): a doc comment written as
  a bare suppression-syntax example (e.g.
  `/// devaudit-ignore: flutter.localization.hardcoded-ui-string` or
  `/// devaudit-ignore-file: flutter.localization.hardcoded-ui-string`,
  with nothing but whitespace before the keyword) will be treated as an
  actual suppression directive. A doc comment merely *mentioning* the
  syntax in a sentence is unaffected, since other words between `//` and
  the keyword prevent a match. This is considered a known, low-probability
  limitation rather than a bug to fix pre-emptively; revisit if it is ever
  encountered in practice.
- There is no `--fix` in this release; DevAudit never modifies scanned
  source files.
