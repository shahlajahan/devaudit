/// DevAudit
///
/// Copyright (c) Pharos Labs.
/// Licensed under the Apache License, Version 2.0.
library;

import 'dart:io';

/// Directory names every built-in file discovery helper skips, regardless
/// of language or plugin: version control metadata and common build/tool
/// output that never contains source a plugin should analyze.
const excludedDirectoryNames = {'.dart_tool', 'build', '.git'};

/// Recursively discovers files under [root], letting [isIncluded] decide
/// whether to descend into a directory or yield a file.
///
/// This is a generic, language-agnostic walker shared by every plugin.
/// Symlinks are never followed, so it is safe to run against project trees
/// that contain circular links. Directories that cannot be listed (for
/// example due to permissions) are skipped rather than throwing.
Iterable<File> discoverFiles({
  required Directory root,
  required bool Function(String path, FileSystemEntityType type) isIncluded,
}) sync* {
  if (!root.existsSync()) return;

  final pending = <Directory>[root];
  while (pending.isNotEmpty) {
    final directory = pending.removeLast();
    List<FileSystemEntity> entities;
    try {
      entities = directory.listSync(followLinks: false);
    } on FileSystemException {
      continue;
    }

    entities.sort((a, b) => a.path.compareTo(b.path));
    for (final entity in entities) {
      final normalizedPath = entity.path.replaceAll('\\', '/');
      if (entity is Directory) {
        if (isIncluded(normalizedPath, FileSystemEntityType.directory)) {
          pending.add(entity);
        }
      } else if (entity is File) {
        if (isIncluded(normalizedPath, FileSystemEntityType.file)) {
          yield entity;
        }
      }
    }
  }
}
