import 'package:devaudit/plugins/flutter/arb/arb_file_discovery.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

const _projectRoot = 'test/fixtures/arb_localization/discovery';

List<String> _relativePaths(ArbFileDiscovery discovery, String projectRoot) =>
    discovery
        .discover(projectRoot)
        .map(
          (file) =>
              p.relative(file.path, from: projectRoot).replaceAll('\\', '/'),
        )
        .toList();

void main() {
  group('ArbFileDiscovery', () {
    const discovery = ArbFileDiscovery();

    test('discovers .arb files anywhere under the project root', () {
      final relativePaths = _relativePaths(discovery, _projectRoot);

      expect(relativePaths, contains('lib/l10n/app_en.arb'));
      expect(relativePaths, contains('lib/l10n/app_tr.arb'));
    });

    test('returns files in deterministic, sorted order', () {
      final relativePaths = _relativePaths(discovery, _projectRoot);
      final sorted = [...relativePaths]..sort();
      expect(relativePaths, equals(sorted));
    });

    test('never descends into build/ or .dart_tool/', () {
      final relativePaths = _relativePaths(discovery, _projectRoot);

      expect(relativePaths.any((path) => path.contains('/build/')), isFalse);
      expect(relativePaths.any((path) => path.contains('.dart_tool')), isFalse);
    });
  });
}
