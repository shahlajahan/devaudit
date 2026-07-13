import 'package:devaudit/devaudit.dart';
import 'package:test/test.dart';

AuditIssue _issue({required String filePath, required int line}) => AuditIssue(
  ruleId: 'r',
  severity: AuditSeverity.warning,
  message: 'message',
  filePath: filePath,
  range: SourceRange(start: SourceLocation(line: line, column: 1)),
);

void main() {
  group('FolderMarkdownBundleGenerator', () {
    const generator = FolderMarkdownBundleGenerator();

    test('mirrors the parent-directory path exactly, per ADR-0003', () {
      final result = AuditResult(
        issues: [
          _issue(
            filePath: 'lib/ui/pet_taxi/pet_taxi_booking_page.dart',
            line: 1,
          ),
        ],
        filesScanned: 1,
        duration: Duration.zero,
      );

      final bundle = generator.generate(result, target: '.');
      expect(bundle.documents.single.path, 'folders/lib/ui/pet_taxi.md');
    });

    test('groups multiple files within the same folder into one document', () {
      final result = AuditResult(
        issues: [
          _issue(filePath: 'lib/ui/a.dart', line: 1),
          _issue(filePath: 'lib/ui/b.dart', line: 1),
        ],
        filesScanned: 2,
        duration: Duration.zero,
      );

      final bundle = generator.generate(result, target: '.');
      expect(bundle.documents.map((d) => d.path), ['folders/lib/ui.md']);

      final content = bundle.documents.single.content;
      expect(content, contains('lib/ui/a.dart'));
      expect(content, contains('lib/ui/b.dart'));
      expect(content, contains('2 finding(s) across 2 file(s)'));
    });

    test('separate folders produce separate documents', () {
      final result = AuditResult(
        issues: [
          _issue(filePath: 'lib/ui/a.dart', line: 1),
          _issue(filePath: 'lib/data/b.dart', line: 1),
        ],
        filesScanned: 2,
        duration: Duration.zero,
      );

      final bundle = generator.generate(result, target: '.');
      expect(bundle.documents.map((d) => d.path).toSet(), {
        'folders/lib/ui.md',
        'folders/lib/data.md',
      });
    });

    test('an empty result produces no documents', () {
      final result = AuditResult(
        issues: const [],
        filesScanned: 0,
        duration: Duration.zero,
      );
      expect(generator.generate(result, target: '.').documents, isEmpty);
    });
  });
}
