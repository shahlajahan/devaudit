/// DevAudit
///
/// Copyright (c) Pharos Labs.
/// Licensed under the Apache License, Version 2.0.
library;

import 'dart:convert';

import 'arb_document.dart';

/// Whether [key] is an ARB metadata key rather than a localization key.
///
/// Per the ARB spec, metadata about a resource (its description, type,
/// placeholders, ...) is stored under a key prefixed with `@`, for example
/// `@save` (metadata for the `save` key) or `@@locale` (file-level
/// metadata). Both forms start with `@`, so a single prefix check covers
/// them without needing to special-case `@@`.
bool isArbMetadataKey(String key) => key.startsWith('@');

/// Parses ARB files into [ArbDocument]s.
///
/// This is a reusable utility shared by every localization rule that needs
/// to read ARB files: parsing (this class) is kept separate from any single
/// rule's comparison logic, so future ARB-based rules can reuse it without
/// depending on the missing-locale-key rule.
class ArbFileParser {
  /// Creates an ARB file parser.
  const ArbFileParser();

  /// Parses the ARB file at [path] with [content].
  ///
  /// Returns `null` if [content] is not valid JSON, or its decoded root is
  /// not a JSON object, so callers can skip malformed or unexpected ARB
  /// files rather than crashing the scan — consistent with how the rest of
  /// DevAudit treats unreadable or invalid input.
  ArbDocument? parse({required String path, required String content}) {
    final Object? decoded;
    try {
      decoded = jsonDecode(content);
    } on FormatException {
      return null;
    }

    if (decoded is! Map<String, Object?>) return null;

    final keys = <String>{
      for (final key in decoded.keys)
        if (!isArbMetadataKey(key)) key,
    };
    return ArbDocument(path: path, keys: keys);
  }
}
