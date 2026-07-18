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
        'flutter.localization.missing-locale-key',
      ]);
    });

    test('supports Dart and ARB files', () {
      const plugin = FlutterAuditPlugin();
      expect(plugin.supports('lib/main.dart'), isTrue);
      expect(plugin.supports('lib/main.g.dart'), isTrue);
      expect(plugin.supports('lib/l10n/app_en.arb'), isTrue);
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

  group('FlutterAuditPlugin missing-locale-key rule', () {
    const ruleId = 'flutter.localization.missing-locale-key';

    test('reports nothing for identical ARBs', () async {
      const plugin = FlutterAuditPlugin();
      final result = await plugin.analyze(
        const AuditContext(
          projectRoot: 'test/fixtures/arb_localization/identical',
        ),
      );

      expect(result.issues.where((issue) => issue.ruleId == ruleId), isEmpty);
    });

    test(
      'reports missing keys across multiple locale files, ignoring metadata',
      () async {
        const plugin = FlutterAuditPlugin();
        final result = await plugin.analyze(
          const AuditContext(
            projectRoot: 'test/fixtures/arb_localization/missing_keys',
          ),
        );

        final issues = result.issues
            .where((issue) => issue.ruleId == ruleId)
            .toList();

        // app_de.arb has every key app_en.arb defines: nothing missing.
        expect(issues.any((issue) => issue.filePath == 'app_de.arb'), isFalse);

        // app_tr.arb is missing "save" and "cancel", but never "@@locale",
        // "@welcome", or "@save" (metadata is never a localization key).
        final trIssues = issues
            .where((issue) => issue.filePath == 'app_tr.arb')
            .toList();
        expect(trIssues.map((issue) => issue.evidence), ['cancel', 'save']);
        expect(
          trIssues.every((issue) => issue.severity == AuditSeverity.warning),
          isTrue,
        );
        expect(
          trIssues.any((issue) => (issue.evidence ?? '').startsWith('@')),
          isFalse,
        );
      },
    );

    test(
      'falls back to the first discovered ARB file when app_en.arb is absent',
      () async {
        const plugin = FlutterAuditPlugin();
        final result = await plugin.analyze(
          const AuditContext(
            projectRoot: 'test/fixtures/arb_localization/no_reference_en',
          ),
        );

        final issues = result.issues
            .where((issue) => issue.ruleId == ruleId)
            .toList();

        // app_de.arb sorts before app_fr.arb and becomes the reference; only
        // app_fr.arb (missing "save") is reported against.
        expect(issues, hasLength(1));
        expect(issues.single.filePath, 'app_fr.arb');
        expect(issues.single.evidence, 'save');
      },
    );

    test('reports nothing for empty ARB files', () async {
      const plugin = FlutterAuditPlugin();
      final result = await plugin.analyze(
        const AuditContext(projectRoot: 'test/fixtures/arb_localization/empty'),
      );

      expect(result.issues.where((issue) => issue.ruleId == ruleId), isEmpty);
    });

    test('skips a malformed ARB file instead of crashing the scan', () async {
      const plugin = FlutterAuditPlugin();
      final result = await plugin.analyze(
        const AuditContext(
          projectRoot: 'test/fixtures/arb_localization/malformed',
        ),
      );

      // Fewer than two valid ARB documents remain once app_tr.arb is
      // discarded as malformed, so no comparison is possible or attempted.
      expect(result.issues.where((issue) => issue.ruleId == ruleId), isEmpty);
    });
  });
}
