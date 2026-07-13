/// DevAudit
///
/// Copyright (c) Pharos Labs.
/// Licensed under the Apache License, Version 2.0.
library;

import 'package:meta/meta.dart';

/// A single point in a source file, expressed with one-based [line] and
/// [column] numbers.
///
/// One-based numbering matches how humans and editors reference source code
/// and is required for every location surfaced in a public report.
///
/// Since: 0.1.0-dev.1
@immutable
final class SourceLocation implements Comparable<SourceLocation> {
  /// Creates a source location pointing at [line] and [column].
  ///
  /// Both [line] and [column] must be one-based (that is, `>= 1`).
  const SourceLocation({required this.line, required this.column})
    : assert(line >= 1, 'line must be one-based'),
      assert(column >= 1, 'column must be one-based');

  /// The one-based line number.
  final int line;

  /// The one-based column number.
  final int column;

  /// A deterministic JSON representation of this location.
  Map<String, Object?> toJson() => {'line': line, 'column': column};

  @override
  int compareTo(SourceLocation other) {
    final lineComparison = line.compareTo(other.line);
    if (lineComparison != 0) return lineComparison;
    return column.compareTo(other.column);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SourceLocation && other.line == line && other.column == column);

  @override
  int get hashCode => Object.hash(line, column);

  /// Returns `'line:column'`, for debugging and log output only.
  ///
  /// This format is not a stable public contract: it may change between
  /// versions, and consumers must not parse it.
  @override
  String toString() => '$line:$column';
}
