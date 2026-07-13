import 'package:devaudit/devaudit.dart';
import 'package:test/test.dart';

class _FakePlugin extends AuditPlugin {
  _FakePlugin({
    required this.pluginId,
    this.issues = const [],
    this.filesScanned = 0,
    this.error,
  });

  final String pluginId;
  final List<AuditIssue> issues;
  final int filesScanned;
  final Object? error;

  @override
  String get id => pluginId;

  @override
  String get displayName => pluginId;

  @override
  List<AuditRuleMetadata> get rules => const [];

  @override
  bool supports(String filePath) => true;

  @override
  Future<PluginAnalysisResult> analyze(AuditContext context) async {
    if (error != null) throw error!;
    return PluginAnalysisResult(issues: issues, filesScanned: filesScanned);
  }
}

AuditIssue _issue({
  required String filePath,
  required int line,
  required int column,
  String ruleId = 'fake.rule',
}) => AuditIssue(
  ruleId: ruleId,
  severity: AuditSeverity.warning,
  message: 'message',
  filePath: filePath,
  range: SourceRange(
    start: SourceLocation(line: line, column: column),
  ),
);

void main() {
  group('AuditEngine', () {
    test('combines issues from every registered plugin', () async {
      final pluginA = _FakePlugin(
        pluginId: 'a',
        filesScanned: 2,
        issues: [_issue(filePath: 'lib/a.dart', line: 1, column: 1)],
      );
      final pluginB = _FakePlugin(
        pluginId: 'b',
        filesScanned: 3,
        issues: [_issue(filePath: 'lib/b.dart', line: 1, column: 1)],
      );

      final engine = AuditEngine(plugins: [pluginA, pluginB]);
      final result = await engine.run(
        const AuditContext(projectRoot: '/project'),
      );

      expect(result.issues, hasLength(2));
      expect(result.filesScanned, 5);
      expect(result.pluginSummaries.map((s) => s.pluginId), ['a', 'b']);
      expect(result.pluginSummaries.every((s) => s.succeeded), isTrue);
    });

    test(
      'sorts issues by file path, then line, then column, then rule ID',
      () async {
        final plugin = _FakePlugin(
          pluginId: 'fake',
          issues: [
            _issue(filePath: 'lib/b.dart', line: 1, column: 1),
            _issue(
              filePath: 'lib/a.dart',
              line: 5,
              column: 1,
              ruleId: 'z.rule',
            ),
            _issue(
              filePath: 'lib/a.dart',
              line: 5,
              column: 1,
              ruleId: 'a.rule',
            ),
            _issue(filePath: 'lib/a.dart', line: 2, column: 9),
          ],
        );

        final engine = AuditEngine(plugins: [plugin]);
        final result = await engine.run(
          const AuditContext(projectRoot: '/project'),
        );

        expect(
          result.issues.map(
            (i) =>
                '${i.filePath}:${i.range.startLine}:${i.range.startColumn}:${i.ruleId}',
          ),
          [
            'lib/a.dart:2:9:fake.rule',
            'lib/a.dart:5:1:a.rule',
            'lib/a.dart:5:1:z.rule',
            'lib/b.dart:1:1:fake.rule',
          ],
        );
      },
    );

    test(
      'records a failed plugin without aborting the rest of the audit',
      () async {
        final failing = _FakePlugin(
          pluginId: 'broken',
          error: StateError('boom'),
        );
        final healthy = _FakePlugin(
          pluginId: 'healthy',
          filesScanned: 1,
          issues: [_issue(filePath: 'lib/a.dart', line: 1, column: 1)],
        );

        final engine = AuditEngine(plugins: [failing, healthy]);
        final result = await engine.run(
          const AuditContext(projectRoot: '/project'),
        );

        expect(result.issues, hasLength(1));
        expect(result.filesScanned, 1);

        final brokenSummary = result.pluginSummaries.firstWhere(
          (s) => s.pluginId == 'broken',
        );
        expect(brokenSummary.succeeded, isFalse);
        expect(brokenSummary.error, contains('boom'));

        final healthySummary = result.pluginSummaries.firstWhere(
          (s) => s.pluginId == 'healthy',
        );
        expect(healthySummary.succeeded, isTrue);
      },
    );
  });

  group('AuditResult', () {
    test('counts issues by severity', () {
      final result = AuditResult(
        issues: [
          AuditIssue(
            ruleId: 'r',
            severity: AuditSeverity.warning,
            message: 'm',
            filePath: 'lib/a.dart',
            range: const SourceRange(start: SourceLocation(line: 1, column: 1)),
          ),
          AuditIssue(
            ruleId: 'r',
            severity: AuditSeverity.error,
            message: 'm',
            filePath: 'lib/a.dart',
            range: const SourceRange(start: SourceLocation(line: 2, column: 1)),
          ),
          AuditIssue(
            ruleId: 'r',
            severity: AuditSeverity.warning,
            message: 'm',
            filePath: 'lib/a.dart',
            range: const SourceRange(start: SourceLocation(line: 3, column: 1)),
          ),
        ],
        filesScanned: 1,
        duration: Duration.zero,
      );

      expect(result.warningCount, 2);
      expect(result.errorCount, 1);
      expect(result.infoCount, 0);
    });
  });
}
