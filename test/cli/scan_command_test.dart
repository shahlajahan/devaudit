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

  group('devaudit scan --min-severity', () {
    late Directory tempDir;

    setUp(
      () => tempDir = Directory.systemTemp.createTempSync('devaudit_test_'),
    );
    tearDown(() => tempDir.deleteSync(recursive: true));

    test(
      'an invalid --min-severity returns the usage error exit code',
      () async {
        final exitCode = await DevAuditCommandRunner().run([
          'scan',
          _fixtureRoot,
          '--min-severity=critical',
        ]);
        expect(exitCode, 2);
      },
    );

    test('defaults to info, matching today\'s unfiltered behavior', () async {
      final outputPath = p.join(tempDir.path, 'report.json');
      await DevAuditCommandRunner().run([
        'scan',
        _fixtureRoot,
        '--format=json',
        '--fail-on=none',
        '--output=$outputPath',
      ]);
      final decoded =
          jsonDecode(File(outputPath).readAsStringSync())
              as Map<String, Object?>;

      // This fixture only ever produces warning-severity issues.
      expect(decoded['issueCount'], 14);
      expect(decoded['warningCount'], 14);
    });

    test(
      '--min-severity=warning is unaffected by an all-warning result',
      () async {
        final outputPath = p.join(tempDir.path, 'report.json');
        await DevAuditCommandRunner().run([
          'scan',
          _fixtureRoot,
          '--format=json',
          '--fail-on=none',
          '--min-severity=warning',
          '--output=$outputPath',
        ]);
        final decoded =
            jsonDecode(File(outputPath).readAsStringSync())
                as Map<String, Object?>;

        expect(decoded['issueCount'], 14);
      },
    );

    test(
      '--min-severity=error hides every issue from the report, but '
      '--fail-on=warning still fails (fail-on uses the unfiltered result)',
      () async {
        final outputPath = p.join(tempDir.path, 'report.json');
        final exitCode = await DevAuditCommandRunner().run([
          'scan',
          _fixtureRoot,
          '--format=json',
          '--fail-on=warning',
          '--min-severity=error',
          '--output=$outputPath',
        ]);

        // The rendered report is fully filtered...
        final decoded =
            jsonDecode(File(outputPath).readAsStringSync())
                as Map<String, Object?>;
        expect(decoded['issueCount'], 0);
        expect(decoded['warningCount'], 0);
        expect((decoded['issues'] as List), isEmpty);

        // ...but CI behavior is untouched: --fail-on still evaluates the
        // original, unfiltered scan, which does contain warnings.
        expect(exitCode, 1);
      },
    );

    test(
      'the console report reflects --min-severity=error the same way',
      () async {
        final outputPath = p.join(tempDir.path, 'report.txt');
        await DevAuditCommandRunner().run([
          'scan',
          _fixtureRoot,
          '--fail-on=none',
          '--min-severity=error',
          '--output=$outputPath',
        ]);
        final content = File(outputPath).readAsStringSync();

        expect(content, contains('No issues found.'));
        expect(content, contains('Issues: 0'));
      },
    );
  });

  group('devaudit scan --report dependency validation', () {
    test('--report-folders without --report is a usage error', () async {
      final exitCode = await DevAuditCommandRunner().run([
        'scan',
        _fixtureRoot,
        '--report-folders',
      ]);
      expect(exitCode, 2);
    });

    test('--agent-tasks without --report is a usage error', () async {
      final exitCode = await DevAuditCommandRunner().run([
        'scan',
        _fixtureRoot,
        '--agent-tasks',
      ]);
      expect(exitCode, 2);
    });

    test('--report-dir without --report is a usage error', () async {
      final exitCode = await DevAuditCommandRunner().run([
        'scan',
        _fixtureRoot,
        '--report-dir=somewhere',
      ]);
      expect(exitCode, 2);
    });
  });

  group('devaudit scan --report', () {
    late Directory tempDir;

    setUp(
      () => tempDir = Directory.systemTemp.createTempSync(
        'devaudit_report_test_',
      ),
    );
    tearDown(() => tempDir.deleteSync(recursive: true));

    test(
      'generates summary.md, summary.json, and files/** under --report-dir',
      () async {
        final reportDir = p.join(tempDir.path, 'out');
        final exitCode = await DevAuditCommandRunner().run([
          'scan',
          _fixtureRoot,
          '--report',
          '--report-dir=$reportDir',
          '--fail-on=none',
        ]);

        expect(exitCode, 0);
        expect(File(p.join(reportDir, 'summary.md')).existsSync(), isTrue);
        expect(File(p.join(reportDir, 'summary.json')).existsSync(), isTrue);
        expect(
          File(p.join(reportDir, '.devaudit-report')).existsSync(),
          isTrue,
        );
        expect(
          File(
            p.join(reportDir, 'files', 'lib', 'positive_cases.dart.md'),
          ).existsSync(),
          isTrue,
        );
        // Not requested, so must not be present.
        expect(Directory(p.join(reportDir, 'folders')).existsSync(), isFalse);
        expect(Directory(p.join(reportDir, 'agent')).existsSync(), isFalse);
      },
    );

    test('--report-folders additionally writes folders/**', () async {
      final reportDir = p.join(tempDir.path, 'out');
      await DevAuditCommandRunner().run([
        'scan',
        _fixtureRoot,
        '--report',
        '--report-folders',
        '--report-dir=$reportDir',
        '--fail-on=none',
      ]);

      expect(File(p.join(reportDir, 'folders', 'lib.md')).existsSync(), isTrue);
    });

    test('--agent-tasks additionally writes agent/ (not hidden)', () async {
      final reportDir = p.join(tempDir.path, 'out');
      await DevAuditCommandRunner().run([
        'scan',
        _fixtureRoot,
        '--report',
        '--agent-tasks',
        '--report-dir=$reportDir',
        '--fail-on=none',
      ]);

      expect(
        File(p.join(reportDir, 'agent', 'manifest.json')).existsSync(),
        isTrue,
      );
      expect(Directory(p.join(reportDir, '.agent')).existsSync(), isFalse);
    });

    test(
      'the bundle reflects --min-severity filtering, same as the traditional report',
      () async {
        final reportDir = p.join(tempDir.path, 'out');
        await DevAuditCommandRunner().run([
          'scan',
          _fixtureRoot,
          '--report',
          '--min-severity=error',
          '--report-dir=$reportDir',
          '--fail-on=none',
        ]);

        // This fixture only ever produces warning-severity issues, so at
        // --min-severity=error every per-file document is filtered away.
        final summaryJson =
            jsonDecode(
                  File(p.join(reportDir, 'summary.json')).readAsStringSync(),
                )
                as Map<String, Object?>;
        expect(summaryJson['summary'], containsPair('issues', 0));
        // No per-file documents survive the filter, so files/ is never
        // even created.
        expect(Directory(p.join(reportDir, 'files')).existsSync(), isFalse);
      },
    );

    test(
      '--fail-on still evaluates the unfiltered result even when --report hides everything',
      () async {
        final reportDir = p.join(tempDir.path, 'out');
        final exitCode = await DevAuditCommandRunner().run([
          'scan',
          _fixtureRoot,
          '--report',
          '--min-severity=error',
          '--fail-on=warning',
          '--report-dir=$reportDir',
        ]);

        expect(exitCode, 1);
      },
    );

    test(
      '--format=json and --report can be produced from one invocation',
      () async {
        final reportDir = p.join(tempDir.path, 'out');
        final outputPath = p.join(tempDir.path, 'report.json');
        final exitCode = await DevAuditCommandRunner().run([
          'scan',
          _fixtureRoot,
          '--format=json',
          '--output=$outputPath',
          '--report',
          '--report-dir=$reportDir',
          '--fail-on=none',
        ]);

        expect(exitCode, 0);
        expect(
          (jsonDecode(File(outputPath).readAsStringSync()) as Map)['issues'],
          isNotEmpty,
        );
        expect(File(p.join(reportDir, 'summary.md')).existsSync(), isTrue);
      },
    );

    test(
      're-running against the same report-dir clears stale documents',
      () async {
        final reportDir = p.join(tempDir.path, 'out');
        await DevAuditCommandRunner().run([
          'scan',
          _fixtureRoot,
          '--report',
          '--agent-tasks',
          '--report-dir=$reportDir',
          '--fail-on=none',
        ]);
        expect(
          File(p.join(reportDir, 'agent', 'manifest.json')).existsSync(),
          isTrue,
        );

        // Second run without --agent-tasks: the marker lets devaudit clear
        // the previous run's output, so agent/ must not linger.
        await DevAuditCommandRunner().run([
          'scan',
          _fixtureRoot,
          '--report',
          '--report-dir=$reportDir',
          '--fail-on=none',
        ]);

        expect(Directory(p.join(reportDir, 'agent')).existsSync(), isFalse);
        expect(File(p.join(reportDir, 'summary.md')).existsSync(), isTrue);
      },
    );

    test(
      'refuses to write into a non-empty, unmarked existing directory',
      () async {
        final reportDir = p.join(tempDir.path, 'out');
        Directory(reportDir).createSync(recursive: true);
        File(p.join(reportDir, 'unrelated.txt')).writeAsStringSync('mine');

        final exitCode = await DevAuditCommandRunner().run([
          'scan',
          _fixtureRoot,
          '--report',
          '--report-dir=$reportDir',
          '--fail-on=none',
        ]);

        expect(exitCode, 2);
        expect(
          File(p.join(reportDir, 'unrelated.txt')).readAsStringSync(),
          'mine',
        );
      },
    );
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
