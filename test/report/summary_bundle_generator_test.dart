import 'dart:convert';

import 'package:devaudit/devaudit.dart';
import 'package:test/test.dart';

AuditIssue _issue({
  required String filePath,
  required int line,
  AuditSeverity severity = AuditSeverity.warning,
  String ruleId = 'flutter.localization.hardcoded-ui-string',
}) => AuditIssue(
  ruleId: ruleId,
  severity: severity,
  message: 'message',
  filePath: filePath,
  range: SourceRange(start: SourceLocation(line: line, column: 1)),
);

void main() {
  group('SummaryBundleGenerator', () {
    const generator = SummaryBundleGenerator();

    test('produces exactly summary.md and summary.json', () {
      final result = AuditResult(
        issues: const [],
        filesScanned: 0,
        duration: Duration.zero,
      );
      final bundle = generator.generate(result, target: '.');

      expect(bundle.documents.map((d) => d.path), [
        'summary.md',
        'summary.json',
      ]);
    });

    test(
      'an empty result renders "No issues found" and zeroed JSON counts',
      () {
        final result = AuditResult(
          issues: const [],
          filesScanned: 3,
          duration: Duration.zero,
        );
        final bundle = generator.generate(result, target: '.');

        final md = bundle.documents
            .firstWhere((d) => d.path == 'summary.md')
            .content;
        expect(md, contains('No issues found.'));

        final json =
            jsonDecode(
                  bundle.documents
                      .firstWhere((d) => d.path == 'summary.json')
                      .content,
                )
                as Map<String, Object?>;
        expect(json['summary'], {'filesScanned': 3, 'issues': 0});
        expect((json['byFolder'] as List), isEmpty);
        expect((json['byFile'] as List), isEmpty);
      },
    );

    test(
      'hotspot tables are sorted by count descending, tie-broken by path',
      () {
        final result = AuditResult(
          issues: [
            _issue(filePath: 'lib/a.dart', line: 1),
            _issue(filePath: 'lib/b.dart', line: 1),
            _issue(filePath: 'lib/b.dart', line: 2),
            _issue(filePath: 'lib/b.dart', line: 3),
            _issue(filePath: 'lib/c.dart', line: 1),
            _issue(filePath: 'lib/c.dart', line: 2),
          ],
          filesScanned: 3,
          duration: Duration.zero,
        );

        final json =
            jsonDecode(
                  generator
                      .generate(result, target: '.')
                      .documents
                      .firstWhere((d) => d.path == 'summary.json')
                      .content,
                )
                as Map<String, Object?>;

        expect(
          (json['byFile'] as List).cast<Map<String, Object?>>().map(
            (e) => e['path'],
          ),
          [
            'lib/b.dart', // count 3
            'lib/c.dart', // count 2
            'lib/a.dart', // count 1
          ],
        );
      },
    );

    test(
      'schemaVersion, tool, and target are present and independent of JsonReporter',
      () {
        final result = AuditResult(
          issues: const [],
          filesScanned: 0,
          duration: Duration.zero,
        );
        final json =
            jsonDecode(
                  generator
                      .generate(result, target: 'my-project')
                      .documents
                      .firstWhere((d) => d.path == 'summary.json')
                      .content,
                )
                as Map<String, Object?>;

        expect(json['schemaVersion'], SummaryBundleGenerator.schemaVersion);
        expect((json['tool'] as Map)['name'], 'devaudit');
        expect(json['target'], 'my-project');
      },
    );

    test('byRule aggregates counts across rule IDs', () {
      final result = AuditResult(
        issues: [
          _issue(filePath: 'lib/a.dart', line: 1, ruleId: 'rule.one'),
          _issue(filePath: 'lib/a.dart', line: 2, ruleId: 'rule.one'),
          _issue(filePath: 'lib/a.dart', line: 3, ruleId: 'rule.two'),
        ],
        filesScanned: 1,
        duration: Duration.zero,
      );

      final json =
          jsonDecode(
                generator
                    .generate(result, target: '.')
                    .documents
                    .firstWhere((d) => d.path == 'summary.json')
                    .content,
              )
              as Map<String, Object?>;

      expect(json['byRule'], {'rule.one': 2, 'rule.two': 1});
    });
  });
}
