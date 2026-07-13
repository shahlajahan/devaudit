/// DevAudit
///
/// Copyright (c) Pharos Labs.
/// Licensed under the Apache License, Version 2.0.
library;

import 'package:meta/meta.dart';

import 'source_location.dart';

/// A span of source code, from a required [start] location to an optional
/// [end] location.
///
/// [end] is optional because some plugins or parsers can only determine
/// where a finding begins, not precisely where it ends. Consumers should
/// treat a `null` [end] as "the exact end is unknown" rather than assuming
/// the range covers a single character.
///
/// Since: 0.1.0-dev.1
@immutable
class SourceRange {
  /// Creates a range starting at [start] and optionally ending at [end].
  const SourceRange({required this.start, this.end});

  /// The location where the range starts.
  final SourceLocation start;

  /// The location where the range ends, or `null` if unknown.
  final SourceLocation? end;

  /// The one-based start line.
  int get startLine => start.line;

  /// The one-based start column.
  int get startColumn => start.column;

  /// The one-based end line, or `null` if unknown.
  int? get endLine => end?.line;

  /// The one-based end column, or `null` if unknown.
  int? get endColumn => end?.column;

  /// A deterministic JSON representation of this range.
  ///
  /// `endLine`/`endColumn` are omitted entirely when [end] is unknown,
  /// rather than serialized as `null`.
  Map<String, Object?> toJson() => {
    'startLine': startLine,
    'startColumn': startColumn,
    if (endLine != null) 'endLine': endLine,
    if (endColumn != null) 'endColumn': endColumn,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SourceRange && other.start == start && other.end == end);

  @override
  int get hashCode => Object.hash(start, end);

  /// Returns `'start'`, or `'start-end'` when [end] is known, for debugging
  /// and log output only.
  ///
  /// This format is not a stable public contract: it may change between
  /// versions, and consumers must not parse it.
  @override
  String toString() => end == null ? start.toString() : '$start-$end';
}
