import 'dart:io';

import 'package:devaudit/cli/report_bundle_writer.dart';
import 'package:devaudit/devaudit.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('isSafeBundlePath', () {
    test('accepts ordinary relative paths', () {
      expect(isSafeBundlePath('summary.md'), isTrue);
      expect(isSafeBundlePath('files/lib/ui/vet_page.dart.md'), isTrue);
      expect(isSafeBundlePath('agent/tasks/0001_vet_page.md'), isTrue);
    });

    test('rejects POSIX-absolute paths', () {
      expect(isSafeBundlePath('/etc/passwd'), isFalse);
    });

    test('rejects Windows-absolute paths (backslash and drive letter)', () {
      expect(isSafeBundlePath(r'\Windows\System32'), isFalse);
      expect(isSafeBundlePath('C:/Windows/System32'), isFalse);
    });

    test('rejects path traversal', () {
      expect(isSafeBundlePath('files/../../etc/passwd'), isFalse);
      expect(isSafeBundlePath('../escape.md'), isFalse);
    });

    test('rejects empty segments and empty paths', () {
      expect(isSafeBundlePath(''), isFalse);
      expect(isSafeBundlePath('files//a.md'), isFalse);
    });
  });

  group('writeReportBundle', () {
    late Directory tempRoot;

    setUp(
      () => tempRoot = Directory.systemTemp.createTempSync(
        'devaudit_bundle_writer_test_',
      ),
    );
    tearDown(() => tempRoot.deleteSync(recursive: true));

    test('creates a missing directory and writes the marker', () {
      final outputDir = Directory(p.join(tempRoot.path, 'missing'));
      writeReportBundle(
        ReportBundle(
          documents: [const ReportDocument(path: 'a.md', content: 'A')],
        ),
        outputDir: outputDir,
      );

      expect(File(p.join(outputDir.path, 'a.md')).existsSync(), isTrue);
      expect(
        File(p.join(outputDir.path, '.devaudit-report')).existsSync(),
        isTrue,
      );
    });

    test('an existing, empty, unmarked directory is safe to use', () {
      final outputDir = Directory(p.join(tempRoot.path, 'empty'))..createSync();
      writeReportBundle(
        ReportBundle(
          documents: [const ReportDocument(path: 'a.md', content: 'A')],
        ),
        outputDir: outputDir,
      );

      expect(File(p.join(outputDir.path, 'a.md')).existsSync(), isTrue);
    });

    test(
      'an existing, marked directory is cleared and rebuilt, dropping stale documents',
      () {
        final outputDir = Directory(p.join(tempRoot.path, 'marked'));
        writeReportBundle(
          ReportBundle(
            documents: [
              const ReportDocument(path: 'stale.md', content: 'stale'),
            ],
          ),
          outputDir: outputDir,
        );
        expect(File(p.join(outputDir.path, 'stale.md')).existsSync(), isTrue);

        writeReportBundle(
          ReportBundle(
            documents: [
              const ReportDocument(path: 'fresh.md', content: 'fresh'),
            ],
          ),
          outputDir: outputDir,
        );

        expect(File(p.join(outputDir.path, 'fresh.md')).existsSync(), isTrue);
        expect(File(p.join(outputDir.path, 'stale.md')).existsSync(), isFalse);
      },
    );

    test(
      'refuses an existing, non-empty, unmarked directory and leaves it untouched',
      () {
        final outputDir = Directory(p.join(tempRoot.path, 'foreign'))
          ..createSync();
        final unrelatedFile = File(p.join(outputDir.path, 'unrelated.txt'))
          ..writeAsStringSync('do not touch');

        expect(
          () => writeReportBundle(
            ReportBundle(
              documents: [const ReportDocument(path: 'a.md', content: 'A')],
            ),
            outputDir: outputDir,
          ),
          throwsA(isA<UnsafeReportDirectoryException>()),
        );

        expect(unrelatedFile.existsSync(), isTrue);
        expect(unrelatedFile.readAsStringSync(), 'do not touch');
        expect(File(p.join(outputDir.path, 'a.md')).existsSync(), isFalse);
      },
    );

    test('creates parent directories for nested document paths', () {
      final outputDir = Directory(p.join(tempRoot.path, 'nested'));
      writeReportBundle(
        ReportBundle(
          documents: [
            const ReportDocument(
              path: 'files/lib/ui/pet_taxi/pet_taxi_booking_page.dart.md',
              content: 'content',
            ),
          ],
        ),
        outputDir: outputDir,
      );

      final written = File(
        p.join(
          outputDir.path,
          'files',
          'lib',
          'ui',
          'pet_taxi',
          'pet_taxi_booking_page.dart.md',
        ),
      );
      expect(written.existsSync(), isTrue);
      expect(written.readAsStringSync(), 'content');
    });

    test('rejects an unsafe document path before writing anything', () {
      final outputDir = Directory(p.join(tempRoot.path, 'unsafe'));
      expect(
        () => writeReportBundle(
          ReportBundle(
            documents: [
              const ReportDocument(path: '../escape.md', content: 'E'),
            ],
          ),
          outputDir: outputDir,
        ),
        throwsArgumentError,
      );
      expect(outputDir.existsSync(), isFalse);
    });
  });
}
