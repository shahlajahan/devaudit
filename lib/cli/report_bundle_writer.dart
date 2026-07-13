/// DevAudit
///
/// Copyright (c) Pharos Labs.
/// Licensed under the Apache License, Version 2.0.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/report/report_bundle.dart';

const _markerFileName = '.devaudit-report';

final _driveLetterPattern = RegExp(r'^[a-zA-Z]:');

/// Thrown when the report output directory exists, is not empty, and does
/// not contain the `.devaudit-report` ownership marker — writing would
/// require overwriting directory contents DevAudit cannot prove it owns.
class UnsafeReportDirectoryException implements Exception {
  /// Creates the exception for the directory at [directoryPath].
  const UnsafeReportDirectoryException(this.directoryPath);

  /// The path of the directory that was refused.
  final String directoryPath;

  @override
  String toString() =>
      'Report directory "$directoryPath" already exists, is not empty, and '
      'has no $_markerFileName marker. Refusing to overwrite it.';
}

/// Whether [path] is safe to treat as a bundle-relative path: not empty,
/// not absolute (POSIX `/`, Windows `\`, or a drive letter), and free of
/// `.`/`..` path-traversal segments.
///
/// Every built-in [ReportBundleGenerator] only ever produces safe,
/// relative paths; this is a defensive check against a misbehaving custom
/// generator, since [ReportBundleGenerator] is a public contract.
bool isSafeBundlePath(String path) {
  if (path.isEmpty) return false;
  if (path.startsWith('/') || path.startsWith(r'\')) return false;
  if (_driveLetterPattern.hasMatch(path)) return false;

  final segments = path.split(RegExp(r'[\\/]'));
  if (segments.any(
    (segment) => segment == '.' || segment == '..' || segment.isEmpty,
  )) {
    return false;
  }
  return true;
}

/// Writes every document in [bundle] under [outputDir], mirroring each
/// document's forward-slash [ReportDocument.path] as a real filesystem
/// path and creating parent directories as needed.
///
/// Output-directory ownership rules (see ADR-0003):
///
/// - a missing directory is created;
/// - an existing, empty directory is safe to use, marker or not;
/// - an existing directory containing the `.devaudit-report` marker is
///   treated as owned by a previous run: it is cleared (deleted and
///   recreated) and rebuilt from scratch, so a document for a file that no
///   longer has findings never lingers from a previous run;
/// - an existing, non-empty directory without the marker is never
///   touched — [UnsafeReportDirectoryException] is thrown instead.
///
/// Throws [ArgumentError] if any document's path fails
/// [isSafeBundlePath].
void writeReportBundle(ReportBundle bundle, {required Directory outputDir}) {
  for (final document in bundle.documents) {
    if (!isSafeBundlePath(document.path)) {
      throw ArgumentError.value(
        document.path,
        'path',
        'must be a safe, relative bundle path with no traversal',
      );
    }
  }

  final markerFile = File(p.join(outputDir.path, _markerFileName));

  if (outputDir.existsSync()) {
    final isEmpty = outputDir.listSync().isEmpty;
    final hasMarker = markerFile.existsSync();

    if (!isEmpty && !hasMarker) {
      throw UnsafeReportDirectoryException(outputDir.path);
    }

    if (hasMarker) {
      outputDir.deleteSync(recursive: true);
    }
  }

  outputDir.createSync(recursive: true);
  markerFile.writeAsStringSync(
    'This directory is managed by devaudit. Its contents are replaced on '
    'every `devaudit scan --report` run.\n',
  );

  for (final document in bundle.documents) {
    final segments = document.path.split('/');
    final file = File(p.joinAll([outputDir.path, ...segments]));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(document.content);
  }
}
