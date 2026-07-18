import 'package:devaudit/devaudit.dart';
import 'package:devaudit/plugins/flutter/arb/arb_document.dart';
import 'package:devaudit/plugins/flutter/rules/missing_locale_key_rule.dart';
import 'package:test/test.dart';

void main() {
  group('MissingLocaleKeyRule', () {
    const rule = MissingLocaleKeyRule();

    test('exposes stable metadata', () {
      expect(rule.metadata.id, 'flutter.localization.missing-locale-key');
      expect(rule.metadata.defaultSeverity, AuditSeverity.warning);
      expect(rule.metadata.category, AuditCategory.localization);
    });

    test('reports nothing for identical ARBs', () {
      const reference = ArbDocument(
        path: 'lib/l10n/app_en.arb',
        keys: {'welcome', 'save'},
      );
      const locale = ArbDocument(
        path: 'lib/l10n/app_tr.arb',
        keys: {'welcome', 'save'},
      );

      final issues = rule.evaluate(reference: reference, locales: [locale]);
      expect(issues, isEmpty);
    });

    test('reports one missing key', () {
      const reference = ArbDocument(
        path: 'lib/l10n/app_en.arb',
        keys: {'welcome', 'save'},
      );
      const locale = ArbDocument(
        path: 'lib/l10n/app_tr.arb',
        keys: {'welcome'},
      );

      final issues = rule.evaluate(reference: reference, locales: [locale]);

      expect(issues, hasLength(1));
      final issue = issues.single;
      expect(issue.ruleId, 'flutter.localization.missing-locale-key');
      expect(issue.severity, AuditSeverity.warning);
      expect(issue.filePath, 'lib/l10n/app_tr.arb');
      expect(
        issue.message,
        'Localization key "save" is missing from app_tr.arb.',
      );
      expect(issue.evidence, 'save');
      expect(issue.range.startLine, 1);
      expect(issue.range.startColumn, 1);
    });

    test('reports multiple missing keys, sorted deterministically', () {
      const reference = ArbDocument(
        path: 'lib/l10n/app_en.arb',
        keys: {'welcome', 'save', 'cancel'},
      );
      const locale = ArbDocument(path: 'lib/l10n/app_tr.arb', keys: {});

      final issues = rule.evaluate(reference: reference, locales: [locale]);

      expect(issues.map((issue) => issue.evidence), [
        'cancel',
        'save',
        'welcome',
      ]);
    });

    test('compares every locale file independently', () {
      const reference = ArbDocument(
        path: 'lib/l10n/app_en.arb',
        keys: {'welcome', 'save'},
      );
      const tr = ArbDocument(path: 'lib/l10n/app_tr.arb', keys: {'welcome'});
      const de = ArbDocument(
        path: 'lib/l10n/app_de.arb',
        keys: {'welcome', 'save'},
      );

      final issues = rule.evaluate(reference: reference, locales: [tr, de]);

      expect(issues, hasLength(1));
      expect(issues.single.filePath, 'lib/l10n/app_tr.arb');
      expect(issues.single.evidence, 'save');
    });

    test('never reports a finding against the reference file itself', () {
      const reference = ArbDocument(
        path: 'lib/l10n/app_en.arb',
        keys: {'welcome', 'save'},
      );
      const locale = ArbDocument(
        path: 'lib/l10n/app_tr.arb',
        keys: {'welcome'},
      );

      final issues = rule.evaluate(reference: reference, locales: [locale]);

      expect(issues.every((issue) => issue.filePath != reference.path), isTrue);
    });
  });
}
