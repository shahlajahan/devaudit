/// DevAudit
///
/// Copyright (c) Pharos Labs.
/// Licensed under the Apache License, Version 2.0.
library;

import 'package:meta/meta.dart';

/// A single named document within a [ReportBundle].
///
/// [path] is a forward-slash relative path within the bundle, for example
/// `files/lib/ui/vet_page.dart.md`. It is not a filesystem path: whether
/// and how it is written to disk is a CLI-layer concern.
///
/// Since: 0.1.0-dev.1
@immutable
final class ReportDocument {
  /// Creates a report document.
  const ReportDocument({required this.path, required this.content});

  /// The document's forward-slash relative path within the bundle.
  final String path;

  /// The document's full text content.
  final String content;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReportDocument &&
          other.path == path &&
          other.content == content);

  @override
  int get hashCode => Object.hash(path, content);

  /// Returns [path], for debugging and log output only.
  ///
  /// This format is not a stable public contract: it may change between
  /// versions, and consumers must not parse it.
  @override
  String toString() => path;
}

/// A set of related, independently-addressable documents produced from one
/// [AuditResult] — the multi-file counterpart to [AuditReporter]'s single
/// rendered string.
///
/// A [ReportBundle] is a plain, immutable snapshot: [documents] is
/// defensively copied so nothing can mutate it after construction.
/// Combining bundles produced by different generators, and detecting path
/// collisions between them, is a CLI-layer concern, not a bundle concern —
/// see the (internal) `ReportBundleComposer`.
///
/// Since: 0.1.0-dev.1
final class ReportBundle {
  /// Creates a report bundle containing [documents].
  ReportBundle({required List<ReportDocument> documents})
    : documents = List.unmodifiable(documents);

  /// The documents in this bundle.
  final List<ReportDocument> documents;
}
