/// DevAudit
///
/// Copyright (c) Pharos Labs.
/// Licensed under the Apache License, Version 2.0.
library;

import 'package:meta/meta.dart';

/// The information the engine gives every plugin so it can decide what and
/// how to analyze.
///
/// [AuditContext] intentionally contains only generic, language-agnostic
/// fields. Plugins are responsible for interpreting [projectRoot],
/// [include], and [exclude] in whatever way makes sense for the ecosystem
/// they support (for example, resolving `lib/` as the default Flutter
/// source directory).
///
/// [AuditContext] is a lightweight execution context, not a defensively
/// copied immutable collection: [include] and [exclude] are stored exactly
/// as given. Callers must not mutate a list passed in (or returned) after
/// constructing a context.
///
/// Since: 0.1.0-dev.1
@immutable
class AuditContext {
  /// Creates an audit context rooted at [projectRoot].
  const AuditContext({
    required this.projectRoot,
    this.include = const [],
    this.exclude = const [],
  });

  /// The absolute path to the root of the project being audited.
  ///
  /// Must be an absolute path. This is used internally by plugins to locate
  /// files. It must never be copied verbatim into a report; reports must
  /// only contain paths normalized relative to this root.
  final String projectRoot;

  /// Additional paths to include, beyond a plugin's defaults.
  final List<String> include;

  /// Additional paths to exclude, beyond a plugin's defaults.
  final List<String> exclude;
}
