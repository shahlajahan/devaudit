import 'dart:io';

import 'package:test/test.dart';

/// Exercises the real `bin/devaudit.dart` entry point as a subprocess,
/// rather than calling `DevAuditCommandRunner` in-process (as every other
/// CLI test does). This is the only coverage for `main()` itself: the
/// `exitCode` assignment, and that the process actually terminates with
/// the code the command runner produced.
///
/// Each invocation pays the cost of a fresh `dart run` (source
/// compilation), so this file is intentionally kept to the two cases that
/// matter most for verifying the entry point itself, not general CLI
/// behavior (which is already covered in-process in `test/cli/`).
void main() {
  group('bin/devaudit.dart (subprocess)', () {
    test('--help exits 0', () {
      final result = Process.runSync(Platform.resolvedExecutable, [
        'run',
        'bin/devaudit.dart',
        '--help',
      ]);

      expect(result.exitCode, 0);
      expect(result.stdout, contains('devaudit'));
    });

    test('invalid usage returns the execution error exit code', () {
      final result = Process.runSync(Platform.resolvedExecutable, [
        'run',
        'bin/devaudit.dart',
        'scan',
        'a',
        'b',
      ]);

      expect(result.exitCode, 2);
    });
  });
}
