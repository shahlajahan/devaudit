/// DevAudit
///
/// Copyright (c) Pharos Labs.
/// Licensed under the Apache License, Version 2.0.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../shared/file_discovery.dart';

/// Finds the ARB (Application Resource Bundle) files under a project.
///
/// ARB files may live anywhere in a project (commonly, but not always,
/// under `lib/l10n/`), so this walks the whole project root rather than a
/// single fixed directory, skipping the same directories every other
/// built-in discovery helper skips.
class ArbFileDiscovery {
  /// Creates an ARB file discovery helper.
  const ArbFileDiscovery();

  /// Returns the sorted list of `.arb` files found under [projectRoot].
  List<File> discover(String projectRoot) {
    final files = discoverFiles(
      root: Directory(projectRoot),
      isIncluded: _isIncluded,
    ).toList()..sort((a, b) => a.path.compareTo(b.path));
    return files;
  }

  bool _isIncluded(String path, FileSystemEntityType type) {
    if (type == FileSystemEntityType.directory) {
      return !excludedDirectoryNames.contains(p.basename(path));
    }
    return path.endsWith('.arb');
  }
}
