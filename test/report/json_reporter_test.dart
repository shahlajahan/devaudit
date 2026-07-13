import 'dart:convert';

import 'package:devaudit/devaudit.dart';
import 'package:test/test.dart';

AuditResult _sampleResult() => AuditResult(
  issues: [
    AuditIssue(
      ruleId: 'flutter.localization.hardcoded-ui-string',
      severity: AuditSeverity.warning,
      message: 'Probable user-visible hardcoded string in Text(data: ...).',
      filePath: 'lib/profile_page.dart',
      range: const SourceRange(
        start: SourceLocation(line: 84, column: 12),
        end: SourceLocation(line: 84, column: 22),
      ),
      evidence: "'Followers'",
      suggestion: 'Move this text into localization resources.',
    ),
  ],
  filesScanned: 318,
  duration: const Duration(milliseconds: 420),
);

void main() {
  group('JsonReporter', () {
    const reporter = JsonReporter();

    test('produces valid, schema-versioned JSON with no absolute paths', () {
      final output = reporter.render(_sampleResult(), target: '.');
      final decoded = jsonDecode(output) as Map<String, Object?>;

      expect(decoded['schemaVersion'], '1.0');
      expect(decoded['target'], '.');
      expect((decoded['tool'] as Map)['name'], 'devaudit');
      expect((decoded['tool'] as Map)['version'], isNotEmpty);
      expect(decoded['filesScanned'], 318);
      expect(decoded['warningCount'], 1);
      expect(decoded['errorCount'], 0);

      final issues = decoded['issues'] as List;
      expect(issues, hasLength(1));
      final issue = issues.single as Map<String, Object?>;
      expect(issue['ruleId'], 'flutter.localization.hardcoded-ui-string');
      expect(issue['severity'], 'warning');
      expect(issue['filePath'], 'lib/profile_page.dart');
      expect(issue['filePath'], isNot(contains('\\')));
      expect(issue['range'], {
        'startLine': 84,
        'startColumn': 12,
        'endLine': 84,
        'endColumn': 22,
      });
      expect(issue['evidence'], "'Followers'");
      expect(issue['suggestion'], isNotNull);
    });

    test('is pretty-printed', () {
      final output = reporter.render(_sampleResult(), target: '.');
      expect(output, contains('\n  '));
    });

    test('renders deterministically across repeated calls', () {
      final first = reporter.render(_sampleResult(), target: '.');
      final second = reporter.render(_sampleResult(), target: '.');
      expect(first, equals(second));
    });

    group('rendering a result already filtered by minimum severity', () {
      AuditIssue issueAt(AuditSeverity severity, int line) => AuditIssue(
        ruleId: 'r',
        severity: severity,
        message: 'm',
        filePath: 'lib/a.dart',
        range: SourceRange(start: SourceLocation(line: line, column: 1)),
      );

      AuditResult mixedSeverityResult() => AuditResult(
        issues: [
          issueAt(AuditSeverity.info, 1),
          issueAt(AuditSeverity.warning, 2),
          issueAt(AuditSeverity.error, 3),
        ],
        filesScanned: 3,
        duration: Duration.zero,
      );

      test('info threshold: issueCount equals all three issues', () {
        final filtered = mixedSeverityResult().filteredBySeverity(
          AuditSeverity.info,
        );
        final decoded =
            jsonDecode(reporter.render(filtered, target: '.'))
                as Map<String, Object?>;

        expect(decoded['issueCount'], 3);
        expect(decoded['infoCount'], 1);
        expect(decoded['warningCount'], 1);
        expect(decoded['errorCount'], 1);
        expect((decoded['issues'] as List), hasLength(3));
      });

      test('warning threshold: issueCount matches the filtered set', () {
        final filtered = mixedSeverityResult().filteredBySeverity(
          AuditSeverity.warning,
        );
        final decoded =
            jsonDecode(reporter.render(filtered, target: '.'))
                as Map<String, Object?>;

        expect(decoded['issueCount'], 2);
        expect(decoded['infoCount'], 0);
        expect(decoded['warningCount'], 1);
        expect(decoded['errorCount'], 1);
        final severities = (decoded['issues'] as List)
            .cast<Map<String, Object?>>()
            .map((issue) => issue['severity'])
            .toList();
        expect(severities, ['warning', 'error']);
      });

      test('error threshold: issueCount equals only the error issue', () {
        final filtered = mixedSeverityResult().filteredBySeverity(
          AuditSeverity.error,
        );
        final decoded =
            jsonDecode(reporter.render(filtered, target: '.'))
                as Map<String, Object?>;

        expect(decoded['issueCount'], 1);
        expect(decoded['infoCount'], 0);
        expect(decoded['warningCount'], 0);
        expect(decoded['errorCount'], 1);
        final issues = (decoded['issues'] as List).cast<Map<String, Object?>>();
        expect(issues.single['severity'], 'error');
      });
    });
  });
}
