import 'package:devaudit/devaudit.dart';
import 'package:test/test.dart';

void main() {
  group('AuditIssue', () {
    AuditIssue build({Map<String, Object?>? metadata}) => AuditIssue(
      ruleId: 'flutter.localization.hardcoded-ui-string',
      severity: AuditSeverity.warning,
      message: 'Probable user-visible hardcoded string.',
      filePath: 'lib/home_page.dart',
      range: const SourceRange(
        start: SourceLocation(line: 10, column: 5),
        end: SourceLocation(line: 10, column: 12),
      ),
      evidence: "'Save'",
      suggestion: 'Move this text into localization resources.',
      metadata: metadata,
    );

    test('toJson is deterministic and uses one-based, forward-slash paths', () {
      final issue = build();
      final json = issue.toJson();

      expect(json, {
        'ruleId': 'flutter.localization.hardcoded-ui-string',
        'severity': 'warning',
        'message': 'Probable user-visible hardcoded string.',
        'filePath': 'lib/home_page.dart',
        'range': {
          'startLine': 10,
          'startColumn': 5,
          'endLine': 10,
          'endColumn': 12,
        },
        'evidence': "'Save'",
        'suggestion': 'Move this text into localization resources.',
      });
    });

    test('toJson includes metadata only when present', () {
      final withMetadata = build(metadata: {'widget': 'Text'});
      final withoutMetadata = build();

      expect(withMetadata.toJson()['metadata'], {'widget': 'Text'});
      expect(withoutMetadata.toJson().containsKey('metadata'), isFalse);
    });

    test('two issues with identical fields are equal and share a hashCode', () {
      final a = build(metadata: {'widget': 'Text'});
      final b = build(metadata: {'widget': 'Text'});

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('issues differing only by metadata are not equal', () {
      final a = build(metadata: {'widget': 'Text'});
      final b = build(metadata: {'widget': 'TextSpan'});

      expect(a, isNot(equals(b)));
    });

    test('issues differing by severity are not equal', () {
      final warning = build();
      final error = AuditIssue(
        ruleId: warning.ruleId,
        severity: AuditSeverity.error,
        message: warning.message,
        filePath: warning.filePath,
        range: warning.range,
      );

      expect(warning, isNot(equals(error)));
    });
  });

  group('SourceRange', () {
    test('toJson omits end fields entirely when the end is unknown', () {
      const range = SourceRange(start: SourceLocation(line: 3, column: 1));
      expect(range.toJson(), {'startLine': 3, 'startColumn': 1});
    });
  });
}
