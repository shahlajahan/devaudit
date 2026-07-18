import 'package:devaudit/plugins/flutter/arb/arb_file_parser.dart';
import 'package:test/test.dart';

void main() {
  group('isArbMetadataKey', () {
    test('recognizes @-prefixed keys as metadata', () {
      expect(isArbMetadataKey('@save'), isTrue);
      expect(isArbMetadataKey('@@locale'), isTrue);
    });

    test('does not treat ordinary keys as metadata', () {
      expect(isArbMetadataKey('save'), isFalse);
      expect(isArbMetadataKey('welcome'), isFalse);
    });
  });

  group('ArbFileParser', () {
    const parser = ArbFileParser();

    test('parses localization keys from a well-formed ARB file', () {
      final document = parser.parse(
        path: 'lib/l10n/app_en.arb',
        content: '{"welcome": "Welcome", "save": "Save"}',
      );

      expect(document, isNotNull);
      expect(document!.path, 'lib/l10n/app_en.arb');
      expect(document.keys, {'welcome', 'save'});
    });

    test('ignores @-prefixed metadata keys', () {
      final document = parser.parse(
        path: 'lib/l10n/app_en.arb',
        content: '''
{
  "@@locale": "en",
  "welcome": "Welcome",
  "@welcome": {"description": "Greeting"}
}
''',
      );

      expect(document, isNotNull);
      expect(document!.keys, {'welcome'});
    });

    test('returns an empty key set for an empty ARB file', () {
      final document = parser.parse(path: 'app_en.arb', content: '{}');

      expect(document, isNotNull);
      expect(document!.keys, isEmpty);
    });

    test('returns null for malformed JSON instead of throwing', () {
      expect(
        () => parser.parse(path: 'app_tr.arb', content: '{ not valid json'),
        returnsNormally,
      );
      expect(
        parser.parse(path: 'app_tr.arb', content: '{ not valid json'),
        isNull,
      );
    });

    test('returns null when the decoded JSON root is not an object', () {
      final document = parser.parse(path: 'app_en.arb', content: '["welcome"]');
      expect(document, isNull);
    });
  });
}
