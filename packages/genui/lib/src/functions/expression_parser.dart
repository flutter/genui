// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../model/data_model.dart';
import '../primitives/logging.dart';
import '../primitives/simple_items.dart';
import 'functions.dart';

/// Parses and evaluates expressions in the A2UI `${expression}` format.
class ExpressionParser {
  ExpressionParser(this.context);

  final DataContext context;
  final FunctionRegistry _functions = FunctionRegistry();

  static const int _maxRecursionDepth = 10;

  /// Parses the input string and resolves any embedded expressions.
  ///
  /// If the string contains a single expression that encompasses the entire
  /// string (e.g. "${/foo}"), the return value may be of any type (not just
  /// [String]).
  ///
  /// If the string contains text mixed with expressions (e.g. "Value: ${/foo}"),
  /// the return value will always be a [String].
  ///
  /// This method is the entry point for expression resolution. It handles
  /// escaping of the `${` sequence using a backslash (e.g. `\${`).
  Object? parse(String input) {
    if (!input.contains(r'${')) {
      return input;
    }
    return _parseStringWithInterpolations(input);
  }

  /// Evaluates a logic expression against the current context.
  ///
  /// Supports `and`, `or`, `not`, `call`, `true`, and `false` keys in the
  /// [expression] map.

  bool evaluateLogic(JsonMap expression) {
    if (expression.containsKey('and')) {
      final list = expression['and'] as List;
      return list.every((item) => evaluateLogic(item as JsonMap));
    }
    if (expression.containsKey('or')) {
      final list = expression['or'] as List;
      return list.any((item) => evaluateLogic(item as JsonMap));
    }
    if (expression.containsKey('not')) {
      return !evaluateLogic(expression['not'] as JsonMap);
    }
    if (expression.containsKey('func')) {
      final Object? result = evaluateFunctionCall(expression);
      return result == true;
    }
    if (expression.containsKey('true')) return true;
    if (expression.containsKey('false')) return false;

    // Fallback: strictly assume false for unknown logic operators.
    return false;
  }

  /// Evaluates a function call defined in [callDefinition].
  ///
  /// The [callDefinition] must contain a 'func' key with the function name
  /// and an optional 'args' key with a list of arguments.
  /// Arguments can be literal values, expressions, or nested function calls.
  Object? evaluateFunctionCall(JsonMap callDefinition) {
    final name = callDefinition['func'] as String;
    final List<Object?> args =
        (callDefinition['args'] as List?)?.map((arg) {
          if (arg is String) {
            // Check if it's a path or expression string
            return parse(arg);
          } else if (arg is Map) {
            if (arg.containsKey('path')) {
              return _resolvePath(arg['path'] as String);
            }
            // Literal object
            return arg;
          }
          return arg;
        }).toList() ??
        [];
    return _functions.invoke(name, args);
  }

  Object? _parseStringWithInterpolations(String input) {
    var i = 0;

    final parts = <Object?>[];

    while (i < input.length) {
      final int startIndex = input.indexOf(r'${', i);
      if (startIndex == -1) {
        parts.add(input.substring(i));
        break;
      }

      if (startIndex > 0 && input[startIndex - 1] == r'\') {
        parts.add(input.substring(i, startIndex - 1));
        parts.add(r'${');
        i = startIndex + 2;
        continue;
      }

      if (startIndex > i) {
        parts.add(input.substring(i, startIndex));
      }
      final (String content, int endIndex) = _extractExpressionContent(
        input,
        startIndex + 2,
      );
      if (endIndex == -1) {
        parts.add(input.substring(startIndex));
        break;
      }

      final Object? value = _evaluateExpression(content, 0);
      parts.add(value);

      i = endIndex + 1; // Skip closing '}'
    }

    if (parts.length == 1 && parts[0] is! String) {
      return parts[0];
    }

    return parts.map((e) => e?.toString() ?? '').join('');
  }

  (String, int) _extractExpressionContent(String input, int start) {
    var balance = 1;
    var i = start;
    while (i < input.length) {
      if (input[i] == r'{') {
        balance++;
      } else if (input[i] == r'}') {
        balance--;
        if (balance == 0) {
          return (input.substring(start, i), i);
        }
      }
      if (input[i] == "'" || input[i] == '"') {
        final String quote = input[i];
        i++;
        while (i < input.length) {
          if (input[i] == quote && input[i - 1] != r'\') {
            break;
          }
          i++;
        }
      }
      i++;
    }
    return ('', -1);
  }

  Object? _evaluateExpression(String content, int depth) {
    if (depth > _maxRecursionDepth) {
      genUiLogger.warning(
        'Max recursion depth reached in expression: $content',
      );
      return null;
    }

    content = content.trim();

    final RegExpMatch? funcMatch = RegExp(
      r'^([a-zA-Z0-9_]+)\((.*)\)$',
    ).firstMatch(content);
    if (funcMatch != null) {
      final String funcName = funcMatch.group(1)!;
      final String argsStr = funcMatch.group(2)!;
      final List<Object?> args = _parseArgs(argsStr, depth + 1);
      return _functions.invoke(funcName, args);
    }

    return _resolvePath(content);
  }

  List<Object?> _parseArgs(String argsStr, int depth) {
    final args = <Object?>[];
    var balanceParens = 0;
    var balanceBraces = 0;
    var inQuote = false;
    var quoteChar = '';

    var start = 0;
    for (var i = 0; i < argsStr.length; i++) {
      final String char = argsStr[i];

      if (inQuote) {
        if (char == quoteChar && (i == 0 || argsStr[i - 1] != r'\')) {
          inQuote = false;
        }
        continue;
      }

      if (char == "'" || char == '"') {
        inQuote = true;
        quoteChar = char;
        continue;
      }

      if (char == '(') balanceParens++;
      if (char == ')') balanceParens--;
      if (char == '{') balanceBraces++;
      if (char == '}') balanceBraces--;

      if (char == ',' && balanceParens == 0 && balanceBraces == 0) {
        args.add(_parseArg(argsStr.substring(start, i).trim(), depth));
        start = i + 1;
      }
    }
    args.add(_parseArg(argsStr.substring(start).trim(), depth));

    return args;
  }

  Object? _parseArg(String arg, int depth) {
    if (arg.isEmpty) return null;

    if (arg.startsWith(r'${') && arg.endsWith(r'}')) {
      final String content = arg.substring(2, arg.length - 1);
      return _evaluateExpression(content, depth);
    }

    if (arg.startsWith("'") && arg.endsWith("'")) {
      final String val = arg.substring(1, arg.length - 1);
      return _parseStringWithInterpolations(val);
    }
    if (arg.startsWith('"') && arg.endsWith('"')) {
      final String val = arg.substring(1, arg.length - 1);
      return _parseStringWithInterpolations(val);
    }

    if (arg == 'true') return true;
    if (arg == 'false') return false;
    if (arg == 'null') return null;

    final num? numVal = num.tryParse(arg);
    if (numVal != null) return numVal;

    return arg;
  }

  Object? _resolvePath(String pathStr) {
    pathStr = pathStr.trim();
    return context.getValue(DataPath(pathStr));
  }
}
