import 'dart:convert';

import 'package:devaudit/devaudit.dart';
import 'package:test/test.dart';

AuditIssue _issue({
  required String filePath,
  required int line,
  String ruleId = 'flutter.localization.hardcoded-ui-string',
  String? suggestion,
}) => AuditIssue(
  ruleId: ruleId,
  severity: AuditSeverity.warning,
  message: 'message',
  filePath: filePath,
  range: SourceRange(start: SourceLocation(line: line, column: 1)),
  suggestion: suggestion,
);

void main() {
  group('AgentTaskBundleGenerator', () {
    const generator = AgentTaskBundleGenerator();

    test(
      'numbers tasks 0001, 0002, ... in file order, under agent/ (not hidden)',
      () {
        final result = AuditResult(
          issues: [
            _issue(filePath: 'lib/a.dart', line: 1),
            _issue(filePath: 'lib/b.dart', line: 1),
          ],
          filesScanned: 2,
          duration: Duration.zero,
        );

        final bundle = generator.generate(result, target: '.');
        final taskPaths = bundle.documents
            .map((d) => d.path)
            .where((p) => p.startsWith('agent/tasks/'));

        expect(taskPaths, ['agent/tasks/0001_a.md', 'agent/tasks/0002_b.md']);
        expect(
          bundle.documents.map((d) => d.path),
          contains('agent/manifest.json'),
        );
        expect(
          bundle.documents.map((d) => d.path),
          everyElement(isNot(startsWith('.agent'))),
        );
      },
    );

    test(
      'manifest.json indexes every task with file, findingCount, and ruleIds',
      () {
        final result = AuditResult(
          issues: [
            _issue(filePath: 'lib/a.dart', line: 1, ruleId: 'rule.one'),
            _issue(filePath: 'lib/a.dart', line: 2, ruleId: 'rule.two'),
          ],
          filesScanned: 1,
          duration: Duration.zero,
        );

        final manifest =
            jsonDecode(
                  generator
                      .generate(result, target: '.')
                      .documents
                      .firstWhere((d) => d.path == 'agent/manifest.json')
                      .content,
                )
                as Map<String, Object?>;

        expect(
          manifest['schemaVersion'],
          AgentTaskBundleGenerator.schemaVersion,
        );
        final tasks = (manifest['tasks'] as List).cast<Map<String, Object?>>();
        expect(tasks, hasLength(1));
        expect(tasks.single['file'], 'lib/a.dart');
        expect(tasks.single['task'], 'agent/tasks/0001_a.md');
        expect(tasks.single['findingCount'], 2);
        expect(tasks.single['ruleIds'], ['rule.one', 'rule.two']);
      },
    );

    test(
      'suggested objective includes the safety preamble and distinct suggestions',
      () {
        final result = AuditResult(
          issues: [
            _issue(
              filePath: 'lib/a.dart',
              line: 1,
              suggestion: 'Localize this string.',
            ),
            _issue(
              filePath: 'lib/a.dart',
              line: 2,
              suggestion: 'Localize this string.',
            ),
            _issue(
              filePath: 'lib/a.dart',
              line: 3,
              suggestion: 'Extract this constant.',
            ),
          ],
          filesScanned: 1,
          duration: Duration.zero,
        );

        final content = generator
            .generate(result, target: '.')
            .documents
            .firstWhere((d) => d.path == 'agent/tasks/0001_a.md')
            .content;

        expect(content, contains('Only make the changes described below.'));
        expect(content, contains('Localize this string.'));
        expect(content, contains('Extract this constant.'));
        // Deduplicated: appears once even though two issues share it.
        expect('Localize this string.'.allMatches(content).length, 1);
      },
    );

    test('an empty result still produces a manifest, listing zero tasks', () {
      final result = AuditResult(
        issues: const [],
        filesScanned: 0,
        duration: Duration.zero,
      );
      final bundle = generator.generate(result, target: '.');

      expect(bundle.documents.map((d) => d.path), ['agent/manifest.json']);
      final manifest =
          jsonDecode(bundle.documents.single.content) as Map<String, Object?>;
      expect(manifest['tasks'], isEmpty);
    });
  });
}
