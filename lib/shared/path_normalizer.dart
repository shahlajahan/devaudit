/// DevAudit
///
/// Copyright (c) Pharos Labs.
/// Licensed under the Apache License, Version 2.0.
library;

import 'package:path/path.dart' as p;

/// Normalizes [filePath] into a project-relative path using forward
/// slashes, suitable for storing in an audit issue or including in a
/// report.
///
/// [root] and [filePath] may use either forward or backward slashes; the
/// result always uses forward slashes so reports are stable across
/// operating systems.
String normalizeRelativePath(String root, String filePath) {
  final relative = p.relative(filePath, from: root);
  return p.split(relative).join('/');
}
