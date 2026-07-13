import 'package:devaudit/plugins/flutter/flutter_file_discovery.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

const _projectRoot = 'test/fixtures/flutter_localization';

List<String> _relativePaths(
  FlutterFileDiscovery discovery,
  String projectRoot,
) => discovery
    .discover(projectRoot)
    .map(
      (file) => p.relative(file.path, from: projectRoot).replaceAll('\\', '/'),
    )
    .toList();

void main() {
  group('FlutterFileDiscovery', () {
    const discovery = FlutterFileDiscovery();

    test('discovers Dart files under lib/ in deterministic order', () {
      final relativePaths = _relativePaths(discovery, _projectRoot);

      expect(relativePaths, contains('lib/positive_cases.dart'));
      expect(relativePaths, contains('lib/negative_cases.dart'));

      final sorted = [...relativePaths]..sort();
      expect(relativePaths, equals(sorted));
    });

    test('excludes known code-generation suffixes', () {
      final relativePaths = _relativePaths(discovery, _projectRoot);
      expect(relativePaths.any((path) => path.endsWith('.g.dart')), isFalse);
    });

    test('never descends into build/ or .dart_tool/', () {
      final relativePaths = _relativePaths(discovery, _projectRoot);

      expect(relativePaths.any((path) => path.contains('/build/')), isFalse);
      expect(relativePaths.any((path) => path.contains('.dart_tool')), isFalse);
    });

    test('honors additional exclude patterns', () {
      final relativePaths = _relativePaths(discovery, _projectRoot);
      expect(relativePaths, contains('lib/negative_cases.dart'));

      final withExclude = discovery.discover(
        _projectRoot,
        exclude: ['negative_cases'],
      );
      final excludedPaths = withExclude
          .map(
            (file) =>
                p.relative(file.path, from: _projectRoot).replaceAll('\\', '/'),
          )
          .toList();
      expect(
        excludedPaths.any((path) => path.contains('negative_cases')),
        isFalse,
      );
    });
  });
}
