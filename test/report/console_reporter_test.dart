import 'package:devaudit/devaudit.dart';
import 'package:test/test.dart';

AuditIssue _issue({
  required String filePath,
  required int line,
  required int column,
  String? evidence,
}) => AuditIssue(
  ruleId: 'flutter.localization.hardcoded-ui-string',
  severity: AuditSeverity.warning,
  message: 'Probable user-visible hardcoded string in Text(data: ...).',
  filePath: filePath,
  range: SourceRange(
    start: SourceLocation(line: line, column: column),
  ),
  evidence: evidence,
  suggestion: 'Move this text into localization resources.',
);

void main() {
  group('ConsoleReporter', () {
    const reporter = ConsoleReporter();

    test(
      'groups issues by file and includes line, column, severity, and rule ID',
      () {
        final result = AuditResult(
          issues: [
            _issue(
              filePath: 'lib/profile_page.dart',
              line: 84,
              column: 12,
              evidence: "'Followers'",
            ),
            _issue(
              filePath: 'lib/profile_page.dart',
              line: 91,
              column: 18,
              evidence: "'Following'",
            ),
          ],
          filesScanned: 318,
          duration: const Duration(milliseconds: 420),
        );

        final output = reporter.render(result, target: '.');

        expect(output, contains('lib/profile_page.dart'));
        expect(output, contains('84:12'));
        expect(output, contains('91:18'));
        expect(output, contains('warning'));
        expect(output, contains("'Followers'"));
        expect(output, contains('flutter.localization.hardcoded-ui-string'));
        expect(output, contains('Files scanned: 318'));
        expect(output, contains('Issues: 2'));
        expect(output, contains('Warnings: 2'));
        expect(output, contains('Errors: 0'));
        expect(output, contains('Duration: 420 ms'));
      },
    );

    test('reports no issues clearly', () {
      final result = AuditResult(
        issues: const [],
        filesScanned: 10,
        duration: Duration.zero,
      );
      final output = reporter.render(result, target: '.');

      expect(output, contains('No issues found.'));
    });

    test('surfaces a failed plugin in the summary', () {
      final result = AuditResult(
        issues: const [],
        filesScanned: 0,
        duration: Duration.zero,
        pluginSummaries: const [
          PluginExecutionSummary(
            pluginId: 'flutter',
            filesScanned: 0,
            error: 'boom',
          ),
        ],
      );

      final output = reporter.render(result, target: '.');
      expect(output, contains('plugin "flutter" failed'));
      expect(output, contains('boom'));
    });

    test('never emits ANSI escape sequences', () {
      final result = AuditResult(
        issues: [
          _issue(
            filePath: 'lib/a.dart',
            line: 1,
            column: 1,
            evidence: "'Save'",
          ),
        ],
        filesScanned: 1,
        duration: Duration.zero,
      );

      final output = reporter.render(result, target: '.');
      expect(output, isNot(contains('\x1B[')));
    });
  });
}
