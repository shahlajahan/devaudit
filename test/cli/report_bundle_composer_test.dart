import 'package:devaudit/cli/report_bundle_composer.dart';
import 'package:devaudit/devaudit.dart';
import 'package:test/test.dart';

void main() {
  group('ReportBundleComposer', () {
    const composer = ReportBundleComposer();

    test('combines documents from multiple bundles, preserving order', () {
      final a = ReportBundle(
        documents: [const ReportDocument(path: 'summary.md', content: 'S')],
      );
      final b = ReportBundle(
        documents: [
          const ReportDocument(path: 'files/a.dart.md', content: 'A'),
          const ReportDocument(path: 'files/b.dart.md', content: 'B'),
        ],
      );

      final composed = composer.compose([a, b]);

      expect(composed.documents.map((d) => d.path), [
        'summary.md',
        'files/a.dart.md',
        'files/b.dart.md',
      ]);
    });

    test('throws when two bundles produce the same document path', () {
      final a = ReportBundle(
        documents: [
          const ReportDocument(path: 'files/a.dart.md', content: 'first'),
        ],
      );
      final b = ReportBundle(
        documents: [
          const ReportDocument(path: 'files/a.dart.md', content: 'second'),
        ],
      );

      expect(() => composer.compose([a, b]), throwsStateError);
    });

    test('an empty list of bundles composes to an empty bundle', () {
      expect(composer.compose(const []).documents, isEmpty);
    });
  });
}
