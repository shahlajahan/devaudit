/// DevAudit
///
/// Copyright (c) Pharos Labs.
/// Licensed under the Apache License, Version 2.0.
library;

import 'package:meta/meta.dart';

/// An ARB (Application Resource Bundle) file, parsed down to the
/// localization keys it defines.
///
/// This is a reusable model shared by every localization rule that needs to
/// read ARB files, not just the missing-locale-key rule: only the
/// localization keys are kept, since that is the information common to
/// every ARB-based rule. Metadata entries (keys beginning with `@`, per the
/// ARB spec) are never included in [keys].
///
/// Since: 0.1.0-dev.1
@immutable
class ArbDocument {
  /// Creates a parsed ARB document.
  const ArbDocument({required this.path, required this.keys});

  /// The normalized, project-relative path (forward slashes) of the ARB
  /// file this document was parsed from.
  final String path;

  /// The localization keys defined in this file, excluding metadata keys.
  final Set<String> keys;
}
