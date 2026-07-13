import 'dart:convert';
import 'dart:io';

import 'package:devaudit/cli/devaudit_command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

const _fixtureRoot = 'test/fixtures/flutter_localization';

void main() {
  group('devaudit --help / --version', () {
    test('help exits 0', () async {
      final exitCode = await DevAuditCommandRunner().run(['--help']);
      expect(exitCode, 0);
    });

    test('scan --help exits 0', () async {
      final exitCode = await DevAuditCommandRunner().run(['scan', '--help']);
      expect(exitCode, 0);
    });

    test('version exits 0', () async {
      final exitCode = await DevAuditCommandRunner().run(['--version']);
      expect(exitCode, 0);
    });
  });

  group('devaudit scan usage errors', () {
    test(
      'an invalid --format returns the usage error exit code without a stack trace',
      () async {
        final exitCode = await DevAuditCommandRunner().run([
          'scan',
          _fixtureRoot,
          '--format=xml',
        ]);
        expect(exitCode, 2);
      },
    );

    test(
      'a missing target directory returns the usage error exit code',
      () async {
        final exitCode = await DevAuditCommandRunner().run([
          'scan',
          'does/not/exist',
        ]);
        expect(exitCode, 2);
      },
    );

    test(
      'too many positional arguments returns the usage error exit code',
      () async {
        final exitCode = await DevAuditCommandRunner().run(['scan', 'a', 'b']);
        expect(exitCode, 2);
      },
    );
  });

  group('devaudit scan --fail-on', () {
    late Directory tempDir;

    setUp(
      () => tempDir = Directory.systemTemp.createTempSync('devaudit_test_'),
    );
    tearDown(() => tempDir.deleteSync(recursive: true));

    test('none never fails, even with findings', () async {
      final outputPath = p.join(tempDir.path, 'report.txt');
      final exitCode = await DevAuditCommandRunner().run([
        'scan',
        _fixtureRoot,
        '--fail-on=none',
        '--output=$outputPath',
      ]);
      expect(exitCode, 0);
    });

    test('warning fails when warnings are present', () async {
      final outputPath = p.join(tempDir.path, 'report.txt');
      final exitCode = await DevAuditCommandRunner().run([
        'scan',
        _fixtureRoot,
        '--fail-on=warning',
        '--output=$outputPath',
      ]);
      expect(exitCode, 1);
    });

    test(
      'error does not fail when only warnings are present (this rule never emits errors)',
      () async {
        final outputPath = p.join(tempDir.path, 'report.txt');
        final exitCode = await DevAuditCommandRunner().run([
          'scan',
          _fixtureRoot,
          '--fail-on=error',
          '--output=$outputPath',
        ]);
        expect(exitCode, 0);
      },
    );
  });

  group('devaudit scan --format=json', () {
    late Directory tempDir;

    setUp(
      () => tempDir = Directory.systemTemp.createTempSync('devaudit_test_'),
    );
    tearDown(() => tempDir.deleteSync(recursive: true));

    test('writes valid, deterministic JSON to --output', () async {
      final outputPath = p.join(tempDir.path, 'report.json');
      final exitCode = await DevAuditCommandRunner().run([
        'scan',
        _fixtureRoot,
        '--format=json',
        '--fail-on=none',
        '--output=$outputPath',
      ]);

      expect(exitCode, 0);
      final content = File(outputPath).readAsStringSync();
      final decoded = jsonDecode(content) as Map<String, Object?>;
      expect(decoded['schemaVersion'], '1.0');
      expect((decoded['issues'] as List), isNotEmpty);
    });
  });

  group('devaudit scan does not modify the scanned project', () {
    test('fixture files are untouched after a scan', () async {
      final targetFile = File(
        p.join(_fixtureRoot, 'lib', 'positive_cases.dart'),
      );
      final before = targetFile.readAsStringSync();

      final tempDir = Directory.systemTemp.createTempSync('devaudit_test_');
      addTearDown(() => tempDir.deleteSync(recursive: true));
      final outputPath = p.join(tempDir.path, 'report.txt');

      await DevAuditCommandRunner().run([
        'scan',
        _fixtureRoot,
        '--output=$outputPath',
      ]);

      expect(targetFile.readAsStringSync(), before);
    });
  });
}
