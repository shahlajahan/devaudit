import 'package:devaudit/devaudit.dart';
import 'package:test/test.dart';

void main() {
  group('ReportDocument', () {
    test('two documents with identical fields are equal', () {
      const a = ReportDocument(path: 'summary.md', content: 'hello');
      const b = ReportDocument(path: 'summary.md', content: 'hello');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('documents differing by content are not equal', () {
      const a = ReportDocument(path: 'summary.md', content: 'hello');
      const b = ReportDocument(path: 'summary.md', content: 'world');
      expect(a, isNot(equals(b)));
    });
  });

  group('ReportBundle', () {
    test('documents list is unmodifiable', () {
      final bundle = ReportBundle(
        documents: [const ReportDocument(path: 'a.md', content: 'A')],
      );
      expect(
        () => bundle.documents.add(
          const ReportDocument(path: 'b.md', content: 'B'),
        ),
        throwsUnsupportedError,
      );
    });

    test(
      'mutating the source list after construction does not affect the bundle',
      () {
        final source = [const ReportDocument(path: 'a.md', content: 'A')];
        final bundle = ReportBundle(documents: source);
        source.add(const ReportDocument(path: 'b.md', content: 'B'));

        expect(bundle.documents, hasLength(1));
      },
    );
  });
}
