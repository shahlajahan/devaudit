/// DevAudit
///
/// Copyright (c) Pharos Labs.
/// Licensed under the Apache License, Version 2.0.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

import '../../shared/file_discovery.dart';

const _generatedFileSuffixes = [
  '.g.dart',
  '.freezed.dart',
  '.gr.dart',
  '.config.dart',
  '.mocks.dart',
];

/// The header Flutter and code-generation tools (including `flutter
/// gen-l10n` and `build_runner`) write at the top of generated files.
///
/// This constant is not used for filtering here — suffix- and
/// directory-based exclusion is all this file does. Content-based
/// generated-file detection (for files with this header but no recognized
/// suffix, such as `flutter gen-l10n` output) happens later, inside
/// [FlutterAuditPlugin], after a file's content has been read.
const generatedFileHeaderMarker = 'GENERATED CODE - DO NOT MODIFY BY HAND';

/// Finds the Dart files the Flutter plugin should analyze under
/// [projectRoot].
///
/// By default this walks `lib/`, skipping `.dart_tool/`, `build/`, `.git/`,
/// known code-generation output suffixes, and never following symlinks.
/// [include] may name additional files or directories (relative to
/// [projectRoot] or absolute) to analyze on top of the defaults, and
/// [exclude] adds extra path substrings to skip.
class FlutterFileDiscovery {
  /// Creates a Flutter file discovery helper.
  const FlutterFileDiscovery();

  /// Returns the sorted list of Dart files to analyze.
  List<File> discover(
    String projectRoot, {
    List<String> include = const [],
    List<String> exclude = const [],
  }) {
    final files = <String, File>{};

    final defaultRoot = Directory(p.join(projectRoot, 'lib'));
    for (final file in discoverFiles(
      root: defaultRoot,
      isIncluded: (path, type) => _isIncluded(path, type, exclude),
    )) {
      files[file.path] = file;
    }

    for (final includedPath in include) {
      final resolved = p.isAbsolute(includedPath)
          ? includedPath
          : p.join(projectRoot, includedPath);
      final entityType = FileSystemEntity.typeSync(
        resolved,
        followLinks: false,
      );

      if (entityType == FileSystemEntityType.file) {
        if (_isIncluded(resolved, FileSystemEntityType.file, exclude)) {
          files[resolved] = File(resolved);
        }
      } else if (entityType == FileSystemEntityType.directory) {
        for (final file in discoverFiles(
          root: Directory(resolved),
          isIncluded: (path, type) => _isIncluded(path, type, exclude),
        )) {
          files[file.path] = file;
        }
      }
    }

    final result = files.values.toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    return result;
  }

  bool _isIncluded(
    String path,
    FileSystemEntityType type,
    List<String> exclude,
  ) {
    if (type == FileSystemEntityType.directory) {
      final name = p.basename(path);
      return !excludedDirectoryNames.contains(name);
    }

    if (!path.endsWith('.dart')) return false;
    if (_generatedFileSuffixes.any(path.endsWith)) return false;
    if (exclude.any((pattern) => path.contains(pattern))) return false;

    return true;
  }
}
