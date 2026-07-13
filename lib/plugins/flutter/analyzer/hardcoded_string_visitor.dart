/// DevAudit
///
/// Copyright (c) Pharos Labs.
/// Licensed under the Apache License, Version 2.0.
library;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';

import '../../../core/model/audit_issue.dart';
import '../../../core/model/audit_severity.dart';
import '../../../core/model/source_location.dart';
import '../../../core/model/source_range.dart';

/// Named parameters, keyed by the Flutter widget/class they belong to, whose
/// value is a direct user-visible [String] (as opposed to a `Widget`, which
/// is instead picked up by the generic `Text`/`TextSpan` detection below).
///
/// This table is what lets the visitor cover a large surface of Flutter's
/// API without writing bespoke traversal logic for every widget: any
/// constructor listed here is checked for its named string arguments, and
/// everything else (`AppBar.title`, `ListTile.title`, `SnackBar.content`,
/// button `child`, `Chip.label`, and so on) is covered automatically because
/// those all accept a `Widget`, which typically means a nested `Text(...)`
/// that this visitor will reach during its normal recursive traversal.
const _stringNamedParamsByType = <String, Set<String>>{
  'TextSpan': {'text'},
  'InputDecoration': {
    'labelText',
    'hintText',
    'helperText',
    'errorText',
    'prefixText',
    'suffixText',
    'counterText',
    'semanticCounterText',
  },
  'Tooltip': {'message'},
  'Semantics': {'label', 'hint', 'value', 'increasedValue', 'decreasedValue'},
  'BottomNavigationBarItem': {'label'},
  'NavigationDestination': {'label'},
  'IconButton': {'tooltip'},
  'FloatingActionButton': {'tooltip'},
  'Tab': {'text'},
};

final _hasLetter = RegExp(r'\p{L}', unicode: true);
final _uriSchemePattern = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.\-]*://');
final _routeLikePattern = RegExp(r'^/[a-zA-Z0-9_\-/]*$');
final _dottedKeyPattern = RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*(\.[a-zA-Z0-9_]+)+$');
final _assetPathPattern = RegExp(
  r'^(assets?/.*|.*\.(png|jpe?g|gif|webp|bmp|ico|svg|ttf|otf|woff2?))$',
  caseSensitive: false,
);
final _suppressionLinePattern = RegExp(r'//\s*devaudit-ignore:\s*([\w.\-]+)');

/// Walks a parsed Dart AST looking for probable user-visible hardcoded
/// strings passed to well-known Flutter UI APIs.
///
/// This visitor favors precision over recall: it only inspects arguments
/// that are bare string literals (`SimpleStringLiteral`, `StringInterpolation`,
/// or `AdjacentStrings`). Any other expression shape — a method call such as
/// `.tr()`, a property chain such as `context.l10n.save` or
/// `AppLocalizations.of(context)!.save`, or a call like `Intl.message(...)` —
/// is left untouched, since none of those are themselves a literal node.
/// This is what lets the visitor recognize common localization patterns
/// without needing to special-case each one.
class HardcodedStringVisitor extends RecursiveAstVisitor<void> {
  /// Creates a visitor that reports findings for [ruleId] at [severity],
  /// attributing them to [relativePath].
  HardcodedStringVisitor({
    required this.ruleId,
    required this.severity,
    required this.relativePath,
    required this.lineInfo,
    required this.sourceLines,
  });

  /// The rule ID to attach to every issue this visitor produces.
  final String ruleId;

  /// The severity to attach to every issue this visitor produces.
  final AuditSeverity severity;

  /// The normalized, relative path of the file being visited.
  final String relativePath;

  /// Line/column information for the file being visited.
  final LineInfo lineInfo;

  /// The raw lines of the file being visited, used to look up suppression
  /// comments.
  final List<String> sourceLines;

  /// The issues found so far.
  final List<AuditIssue> issues = [];

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    // Reached when a widget is constructed with an explicit `const`/`new`
    // keyword, e.g. `const Text('Save')`.
    final typeName = node.constructorName.type.name.lexeme;
    final namedConstructor = node.constructorName.name?.name;
    _checkConstructorLikeCall(typeName, namedConstructor, node.argumentList);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // Without type resolution, an un-prefixed call such as `Text('Save')`
    // (the overwhelmingly common style, since `new` is no longer required)
    // is indistinguishable at the syntax level from a plain function call.
    // A `null` target combined with the well-known widget names this
    // visitor looks for is what makes it a reliable constructor-like call.
    if (node.target == null) {
      _checkConstructorLikeCall(node.methodName.name, null, node.argumentList);
    }
    super.visitMethodInvocation(node);
  }

  void _checkConstructorLikeCall(
    String typeName,
    String? namedConstructor,
    ArgumentList argumentList,
  ) {
    final callEndLine = lineInfo
        .getLocation(argumentList.rightParenthesis.offset)
        .lineNumber;

    if (typeName == 'Text' && namedConstructor != 'rich') {
      final dataArgument = _firstPositionalArgument(argumentList);
      if (dataArgument != null) {
        _reportIfLiteral(
          expression: dataArgument,
          widget: 'Text',
          paramLabel: 'data',
          callEndLine: callEndLine,
        );
      }
      return;
    }

    final stringParams = _stringNamedParamsByType[typeName];
    if (stringParams == null) return;

    for (final paramName in stringParams) {
      final argument = _namedArgument(argumentList, paramName);
      if (argument != null) {
        _reportIfLiteral(
          expression: argument,
          widget: typeName,
          paramLabel: paramName,
          callEndLine: callEndLine,
        );
      }
    }
  }

  Expression? _firstPositionalArgument(ArgumentList argumentList) {
    for (final argument in argumentList.arguments) {
      if (argument is! NamedExpression) return argument;
    }
    return null;
  }

  Expression? _namedArgument(ArgumentList argumentList, String name) {
    for (final argument in argumentList.arguments) {
      if (argument is NamedExpression && argument.name.label.name == name) {
        return argument.expression;
      }
    }
    return null;
  }

  void _reportIfLiteral({
    required Expression expression,
    required String widget,
    required String paramLabel,
    required int callEndLine,
  }) {
    final literal = _literalStringInfo(expression);
    if (literal == null) return;
    if (!_looksLikeUserVisibleText(literal.value)) return;
    if (_isSuppressed(expression, callEndLine)) return;

    final start = lineInfo.getLocation(expression.offset);
    final end = lineInfo.getLocation(expression.offset + expression.length);

    issues.add(
      AuditIssue(
        ruleId: ruleId,
        severity: severity,
        message:
            'Probable user-visible hardcoded string in $widget($paramLabel: ...).',
        filePath: relativePath,
        range: SourceRange(
          start: SourceLocation(
            line: start.lineNumber,
            column: start.columnNumber,
          ),
          end: SourceLocation(line: end.lineNumber, column: end.columnNumber),
        ),
        evidence: literal.evidence,
        suggestion:
            "Move this text into the project's localization resources instead of "
            'hardcoding it.',
      ),
    );
  }

  /// Extracts the value and source evidence of [expression] if it is a bare
  /// string literal, or `null` if it is any other kind of expression (such
  /// as a method call or property access — the shape a localized lookup
  /// normally takes).
  _LiteralStringInfo? _literalStringInfo(Expression expression) {
    final unwrapped = _unwrapParens(expression);

    if (unwrapped is SimpleStringLiteral) {
      return _LiteralStringInfo(
        value: unwrapped.value,
        evidence: unwrapped.literal.lexeme,
      );
    }

    if (unwrapped is AdjacentStrings) {
      final buffer = StringBuffer();
      for (final part in unwrapped.strings) {
        if (part is SimpleStringLiteral) {
          buffer.write(part.value);
        } else {
          return null;
        }
      }
      return _LiteralStringInfo(
        value: buffer.toString(),
        evidence: unwrapped.toSource(),
      );
    }

    if (unwrapped is StringInterpolation) {
      final buffer = StringBuffer();
      for (final element in unwrapped.elements) {
        if (element is InterpolationString) buffer.write(element.value);
      }
      return _LiteralStringInfo(
        value: buffer.toString(),
        evidence: unwrapped.toSource(),
      );
    }

    return null;
  }

  Expression _unwrapParens(Expression expression) {
    var current = expression;
    while (current is ParenthesizedExpression) {
      current = current.expression;
    }
    return current;
  }

  bool _looksLikeUserVisibleText(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    if (!_hasLetter.hasMatch(trimmed)) return false;
    if (_uriSchemePattern.hasMatch(trimmed)) return false;
    if (_routeLikePattern.hasMatch(trimmed)) return false;
    if (_dottedKeyPattern.hasMatch(trimmed)) return false;
    if (_assetPathPattern.hasMatch(trimmed)) return false;
    return true;
  }

  /// Whether a suppression comment applies to [expression], either as a
  /// trailing comment on the same line as the literal, a leading comment on
  /// the line immediately above, or a trailing comment on the line where the
  /// enclosing call's closing parenthesis ([callEndLine]) lands.
  ///
  /// Real widget trees are usually one large expression nested inside a
  /// single `return` statement, so suppression is deliberately line-based
  /// rather than tied to Dart statement boundaries — otherwise a comment
  /// placed above a deeply nested `Text(...)` would have no reliable
  /// statement to attach to. Checking [callEndLine] means a suppression
  /// comment survives the formatter wrapping a long call across multiple
  /// lines, since the trailing comment then lands after the closing
  /// parenthesis rather than after the literal itself.
  bool _isSuppressed(Expression expression, int callEndLine) {
    final literalLine = lineInfo.getLocation(expression.offset).lineNumber;
    return _lineHasSuppressionComment(literalLine) ||
        _lineHasSuppressionComment(literalLine - 1) ||
        _lineHasSuppressionComment(callEndLine);
  }

  bool _lineHasSuppressionComment(int oneBasedLine) {
    if (oneBasedLine < 1 || oneBasedLine > sourceLines.length) return false;
    final match = _suppressionLinePattern.firstMatch(
      sourceLines[oneBasedLine - 1],
    );
    return match != null && match.group(1) == ruleId;
  }
}

class _LiteralStringInfo {
  const _LiteralStringInfo({required this.value, required this.evidence});

  final String value;
  final String evidence;
}
