import 'package:devaudit/devaudit.dart';
import 'package:test/test.dart';

AuditIssue _issue({required String filePath, required int line}) => AuditIssue(
  ruleId: 'r',
  severity: AuditSeverity.warning,
  message: 'message',
  filePath: filePath,
  range: SourceRange(start: SourceLocation(line: line, column: 1)),
  evidence: "'text'",
  suggestion: 'Fix it.',
);

void main() {
  group('PerFileMarkdownBundleGenerator', () {
    const generator = PerFileMarkdownBundleGenerator();

    test('mirrors the source path exactly, per ADR-0003', () {
      final result = AuditResult(
        issues: [
          _issue(
            filePath: 'lib/ui/pet_taxi/pet_taxi_booking_page.dart',
            line: 10,
          ),
        ],
        filesScanned: 1,
        duration: Duration.zero,
      );

      final bundle = generator.generate(result, target: '.');

      expect(bundle.documents, hasLength(1));
      expect(
        bundle.documents.single.path,
        'files/lib/ui/pet_taxi/pet_taxi_booking_page.dart.md',
      );
    });

    test('a file with no findings gets no document', () {
      final result = AuditResult(
        issues: [_issue(filePath: 'lib/a.dart', line: 1)],
        filesScanned: 2,
        duration: Duration.zero,
      );

      final bundle = generator.generate(result, target: '.');
      expect(bundle.documents.map((d) => d.path), ['files/lib/a.dart.md']);
    });

    test('an empty result produces no documents at all', () {
      final result = AuditResult(
        issues: const [],
        filesScanned: 0,
        duration: Duration.zero,
      );
      expect(generator.generate(result, target: '.').documents, isEmpty);
    });

    test(
      'document order follows the deterministic issue order (sorted by file path)',
      () {
        final result = AuditResult(
          issues: [
            _issue(filePath: 'lib/b.dart', line: 1),
            _issue(filePath: 'lib/a.dart', line: 1),
          ],
          filesScanned: 2,
          duration: Duration.zero,
        );

        // AuditResult does not re-sort; this generator must preserve
        // whatever order AuditEngine already guarantees. Feed it pre-sorted
        // input, matching what the engine actually produces.
        final sorted = AuditResult(
          issues: [...result.issues]
            ..sort((a, b) => a.filePath.compareTo(b.filePath)),
          filesScanned: 2,
          duration: Duration.zero,
        );

        expect(
          generator.generate(sorted, target: '.').documents.map((d) => d.path),
          ['files/lib/a.dart.md', 'files/lib/b.dart.md'],
        );
      },
    );

    test(
      'a file document lists every finding with evidence and suggestion',
      () {
        final result = AuditResult(
          issues: [_issue(filePath: 'lib/a.dart', line: 7)],
          filesScanned: 1,
          duration: Duration.zero,
        );

        final content = generator
            .generate(result, target: '.')
            .documents
            .single
            .content;
        expect(content, contains('lib/a.dart'));
        expect(content, contains('7:1'));
        expect(content, contains("'text'"));
        expect(content, contains('Fix it.'));
      },
    );
  });
}
