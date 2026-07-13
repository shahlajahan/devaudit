import 'package:devaudit/shared/path_normalizer.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('normalizeRelativePath', () {
    test('produces a forward-slash relative path from an absolute path', () {
      final root = p.join('project');
      final file = p.join('project', 'lib', 'home_page.dart');

      expect(normalizeRelativePath(root, file), 'lib/home_page.dart');
    });

    test('handles nested directories', () {
      final root = p.join('project');
      final file = p.join(
        'project',
        'lib',
        'widgets',
        'buttons',
        'save_button.dart',
      );

      expect(
        normalizeRelativePath(root, file),
        'lib/widgets/buttons/save_button.dart',
      );
    });

    test('never leaves a machine-specific absolute path in the result', () {
      final root = p.join(p.current, 'project');
      final file = p.join(p.current, 'project', 'lib', 'main.dart');

      final result = normalizeRelativePath(root, file);

      expect(result, 'lib/main.dart');
      expect(p.isAbsolute(result), isFalse);
    });
  });
}
