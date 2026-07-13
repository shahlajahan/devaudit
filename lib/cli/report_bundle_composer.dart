/// DevAudit
///
/// Copyright (c) Pharos Labs.
/// Licensed under the Apache License, Version 2.0.
library;

import '../core/report/report_bundle.dart';
import '../core/report/report_bundle_generator.dart';

/// Combines several independently-generated [ReportBundle]s into one,
/// detecting path collisions between them.
///
/// Combining bundles produced by different [ReportBundleGenerator]s (for
/// example, summary + per-file + agent tasks in one `devaudit scan
/// --report` invocation) is an orchestration concern, not something a
/// generator itself should need to know about — see ADR-0003. This class
/// is CLI-internal and intentionally not exported: nothing outside the
/// CLI currently needs to combine bundles.
class ReportBundleComposer {
  /// Creates a report bundle composer.
  const ReportBundleComposer();

  /// Combines [bundles] in order into one [ReportBundle].
  ///
  /// Throws a [StateError] if two bundles contain a document with the same
  /// [ReportDocument.path] — combining must never silently let one
  /// document overwrite another.
  ReportBundle compose(List<ReportBundle> bundles) {
    final seenPaths = <String>{};
    final documents = <ReportDocument>[];

    for (final bundle in bundles) {
      for (final document in bundle.documents) {
        if (!seenPaths.add(document.path)) {
          throw StateError(
            'Duplicate report document path: "${document.path}". Two '
            'report bundle generators produced a document at the same '
            'path.',
          );
        }
        documents.add(document);
      }
    }

    return ReportBundle(documents: documents);
  }
}
