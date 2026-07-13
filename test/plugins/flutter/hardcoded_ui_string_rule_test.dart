import 'dart:io';

import 'package:devaudit/devaudit.dart';
import 'package:devaudit/plugins/flutter/analyzer/dart_file_analyzer.dart';
import 'package:devaudit/plugins/flutter/rules/hardcoded_ui_string_rule.dart';
import 'package:devaudit/shared/path_normalizer.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

const _fixtureRoot = 'test/fixtures/flutter_localization';

List<AuditIssue> _evaluate(String relativeFilePath) {
  final path = p.join(_fixtureRoot, relativeFilePath);
  final content = File(path).readAsStringSync();
  const analyzer = DartFileAnalyzer();
  final parseResult = analyzer.parse(path: path, content: content);
  const rule = HardcodedUiStringRule();

  return rule.evaluate(
    relativePath: normalizeRelativePath(_fixtureRoot, path),
    source: content,
    unit: parseResult.unit,
    lineInfo: parseResult.lineInfo,
  );
}

void main() {
  group('HardcodedUiStringRule positive cases', () {
    late List<AuditIssue> issues;

    setUpAll(() => issues = _evaluate('lib/positive_cases.dart'));

    test('detects every documented high-confidence case', () {
      final evidence = issues.map((issue) => issue.evidence).toList();

      expect(
        evidence,
        containsAll(<String>[
          "'Hello'",
          '"Save"',
          "'Hello \$name'",
          "'Followers'",
          "'Search'",
          "'Refresh'",
          "'Profile image'",
          "'Home'",
          "'Delete'",
          "'Settings'",
        ]),
      );
    });

    test(
      'every issue carries the rule ID, warning severity, and a suggestion',
      () {
        expect(issues, isNotEmpty);
        for (final issue in issues) {
          expect(issue.ruleId, HardcodedUiStringRule.ruleMetadata.id);
          expect(issue.severity, AuditSeverity.warning);
          expect(issue.filePath, 'lib/positive_cases.dart');
          expect(issue.suggestion, isNotNull);
          expect(issue.range.startLine, greaterThan(0));
          expect(issue.range.startColumn, greaterThan(0));
        }
      },
    );
  });

  group('HardcodedUiStringRule negative cases', () {
    test(
      'does not flag localized lookups, logging, routes, map keys, assets, URLs, or non-textual '
      'literals',
      () {
        expect(_evaluate('lib/negative_cases.dart'), isEmpty);
      },
    );
  });

  group('HardcodedUiStringRule suppression', () {
    test(
      'suppresses a same-line trailing comment and a leading-comment line',
      () {
        final issues = _evaluate('lib/suppressed_line.dart');
        expect(issues.map((issue) => issue.evidence), ["'Not suppressed'"]);
      },
    );

    test('suppresses every finding when a file-level marker is present', () {
      expect(_evaluate('lib/suppressed_file.dart'), isEmpty);
    });
  });

  group('HardcodedUiStringRule.ruleMetadata', () {
    test('is the stable, documented rule ID', () {
      expect(
        HardcodedUiStringRule.ruleMetadata.id,
        'flutter.localization.hardcoded-ui-string',
      );
      expect(
        HardcodedUiStringRule.ruleMetadata.category,
        AuditCategory.localization,
      );
      expect(
        HardcodedUiStringRule.ruleMetadata.defaultSeverity,
        AuditSeverity.warning,
      );
    });
  });
}
