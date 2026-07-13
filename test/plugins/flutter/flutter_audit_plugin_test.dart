import 'package:devaudit/devaudit.dart';
import 'package:test/test.dart';

const _fixtureRoot = 'test/fixtures/flutter_localization';

void main() {
  group('FlutterAuditPlugin', () {
    test('exposes stable identity and rule metadata', () {
      const plugin = FlutterAuditPlugin();
      expect(plugin.id, 'flutter');
      expect(plugin.displayName, 'Flutter');
      expect(plugin.rules.map((rule) => rule.id), [
        'flutter.localization.hardcoded-ui-string',
      ]);
    });

    test('supports only Dart files', () {
      const plugin = FlutterAuditPlugin();
      expect(plugin.supports('lib/main.dart'), isTrue);
      expect(plugin.supports('lib/main.g.dart'), isTrue);
      expect(plugin.supports('README.md'), isFalse);
    });

    test('analyzes the fixture project end-to-end', () async {
      const plugin = FlutterAuditPlugin();
      final result = await plugin.analyze(
        const AuditContext(projectRoot: _fixtureRoot),
      );

      // positive_cases.dart (10) + profile_page.dart (3) + suppressed_line.dart (1 unsuppressed).
      expect(result.issues.length, 14);
      expect(
        result.issues.every((issue) => issue.severity == AuditSeverity.warning),
        isTrue,
      );

      // Every reported path must be normalized, relative, and forward-slashed.
      for (final issue in result.issues) {
        expect(issue.filePath, isNot(contains('\\')));
        expect(issue.filePath, isNot(startsWith('/')));
        expect(issue.filePath, startsWith('lib/'));
      }
    });

    test(
      'never reports issues from generated files, regardless of how they are recognized',
      () async {
        const plugin = FlutterAuditPlugin();
        final result = await plugin.analyze(
          const AuditContext(projectRoot: _fixtureRoot),
        );

        final flaggedPaths = result.issues
            .map((issue) => issue.filePath)
            .toSet();
        expect(flaggedPaths.any((path) => path.endsWith('.g.dart')), isFalse);
        expect(
          flaggedPaths,
          isNot(contains('lib/l10n/app_localizations.dart')),
        );
      },
    );

    test('skips syntactically invalid files instead of throwing', () async {
      const plugin = FlutterAuditPlugin();
      final result = await plugin.analyze(
        const AuditContext(projectRoot: _fixtureRoot),
      );

      expect(
        result.issues.any(
          (issue) => issue.filePath == 'lib/broken_syntax.dart',
        ),
        isFalse,
      );
      // The broken file is still counted as scanned; it just contributes no issues.
      expect(result.filesScanned, greaterThan(0));
    });
  });
}
