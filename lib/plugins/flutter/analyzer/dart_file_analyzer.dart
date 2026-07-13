/// DevAudit
///
/// Copyright (c) Pharos Labs.
/// Licensed under the Apache License, Version 2.0.
library;

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';

/// Parses Dart source into an unresolved AST, using `package:analyzer`.
///
/// Full type resolution (which would require a resolved analysis context
/// backed by a package config) is intentionally not used: the hardcoded
/// string rule only needs syntactic information (constructor names,
/// argument names, and literal values), so a lightweight, per-file parse is
/// both simpler and dramatically faster, and lets DevAudit scan a project
/// without first requiring `flutter pub get`.
class DartFileAnalyzer {
  /// Creates a Dart file analyzer.
  const DartFileAnalyzer();

  /// Parses [content] (the source of the file at [path]) into a
  /// [ParseStringResult].
  ///
  /// Parse errors are never thrown; callers should inspect
  /// [ParseStringResult.errors] to decide whether the resulting AST is
  /// reliable enough to analyze.
  ParseStringResult parse({required String path, required String content}) {
    return parseString(content: content, path: path, throwIfDiagnostics: false);
  }

  /// Whether [result] contains a fatal syntax error that makes its AST
  /// unreliable for analysis.
  bool hasSyntaxErrors(ParseStringResult result) =>
      result.errors.any((error) => error.severity == Severity.error);
}
