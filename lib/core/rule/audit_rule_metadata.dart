/// DevAudit
///
/// Copyright (c) Pharos Labs.
/// Licensed under the Apache License, Version 2.0.
library;

import 'package:meta/meta.dart';

import '../model/audit_severity.dart';

/// The category an [AuditRuleMetadata] belongs to.
///
/// This is a small value type rather than an enum so that new plugins can
/// introduce new categories without requiring a change to the core package.
/// New categories are added as named constants only once a real rule needs
/// them (see [localization]); until then, a plugin can always construct one
/// directly, e.g. `AuditCategory('accessibility')`.
///
/// Since: 0.1.0-dev.1
@immutable
class AuditCategory {
  /// Creates a category identified by [value].
  ///
  /// [value] should be a short, lower-case, hyphenated identifier.
  const AuditCategory(this.value);

  /// Findings related to internationalization and localization.
  static const localization = AuditCategory('localization');

  /// The stable, lower-case identifier for this category.
  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditCategory && other.value == value);

  @override
  int get hashCode => value.hashCode;

  /// Returns [value], the stable category identifier, for convenient
  /// string interpolation.
  @override
  String toString() => value;
}

/// Static, human- and machine-readable information describing an
/// [AuditRule].
///
/// Rule metadata is treated as public API: [id] values are relied upon by
/// consumers for suppression, filtering, and reporting, and must never
/// change once published.
///
/// Since: 0.1.0-dev.1
@immutable
class AuditRuleMetadata {
  /// Creates rule metadata.
  const AuditRuleMetadata({
    required this.id,
    required this.name,
    required this.description,
    required this.defaultSeverity,
    required this.category,
  });

  /// The stable, globally unique identifier of the rule.
  ///
  /// By convention this is namespaced as
  /// `<plugin>.<category>.<short-name>`, for example
  /// `flutter.localization.hardcoded-ui-string`.
  final String id;

  /// A short, human-readable name for the rule.
  final String name;

  /// A longer description explaining what the rule detects and why it
  /// matters.
  final String description;

  /// The severity reported when this rule finds an issue and the user has
  /// not overridden it.
  final AuditSeverity defaultSeverity;

  /// The category this rule belongs to.
  final AuditCategory category;

  /// A deterministic JSON representation of this metadata.
  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'defaultSeverity': defaultSeverity.name,
    'category': category.value,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is AuditRuleMetadata && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => id;
}
