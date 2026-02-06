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

  bool evaluateLogic(Object? expression) {
    if (expression is bool) return expression;
    if (expression is! Map) return false;
    final jsonEx = expression as JsonMap;

    if (jsonEx.containsKey('true')) return true;
    if (jsonEx.containsKey('false')) return false;

    if (jsonEx.containsKey('and')) {
      final Object? list = jsonEx['and'];
      if (list is List) {
        return list.every(evaluateLogic);
      }
      return false;
    }

    if (jsonEx.containsKey('or')) {
      final Object? list = jsonEx['or'];
      if (list is List) {
        return list.any(evaluateLogic);
      }
      return false;
    }

    if (jsonEx.containsKey('not')) {
      return !evaluateLogic(jsonEx['not']);
    }

    if (jsonEx.containsKey('call') || jsonEx.containsKey('func')) {
      final Object? result = evaluateFunctionCall(jsonEx);
      return result == true;
    }

    // Support DataBinding (path)
    if (jsonEx.containsKey('path')) {
      final Object? val = _resolvePath(jsonEx['path'] as String);
      return val == true;
    }

    return false;
  }

  /// Evaluates a function call defined in [callDefinition].
  ///
  /// The [callDefinition] must contain a 'call' key with the function name
  /// and an optional 'args' key with a map of arguments.
  Object? evaluateFunctionCall(JsonMap callDefinition) {
    final name = (callDefinition['call'] ?? callDefinition['func']) as String;
    final Map<String, Object?> args = {};
    final Object? argsJson = callDefinition['args'];

    if (argsJson is Map) {
      for (final Object? key in argsJson.keys) {
        final argName = key.toString();
        final Object? value = argsJson[key];
        if (value is String) {
          args[argName] = parse(value);
        } else if (value is Map && value.containsKey('path')) {
          args[argName] = _resolvePath(value['path'] as String);
        } else if (value is Map &&
            (value.containsKey('call') || value.containsKey('func'))) {
          // Recursive evaluation for nested calls
          args[argName] = evaluateFunctionCall(value as JsonMap);
        } else {
          args[argName] = value;
        }
      }
    } else if (argsJson is List) {
      // Graceful fallback for legacy list args - best effort or error?
      // Since we are enforcing named args, this might fail unless we map by
      // index?
      // But we don't know parameter names here.
      // We'll log a warning and possibly fail.
      genUiLogger.warning(
        'Function $name called with List args, expected Map. '
        'Arguments dropped.',
      );
    }

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
      final Map<String, Object?> args = _parseNamedArgs(argsStr, depth + 1);
      return _functions.invoke(funcName, args);
    }

    return _resolvePath(content);
  }

  Map<String, Object?> _parseNamedArgs(String argsStr, int depth) {
    final args = <String, Object?>{};
    var balanceParens = 0;
    var balanceBraces = 0;
    var inQuote = false;
    var quoteChar = '';

    var start = 0;

    void processArg(String segment) {
      segment = segment.trim();
      if (segment.isEmpty) return;

      final int colonIndex = segment.indexOf(':');
      if (colonIndex != -1) {
        final String key = segment.substring(0, colonIndex).trim();
        final String valueStr = segment.substring(colonIndex + 1).trim();
        args[key] = _parseArg(valueStr, depth);
      } else {
        // Fallback for positional args? Or ignore?
        // We could support implicit value arg if strictly 1 arg and no name?
        // But let's stick to named.
        // Effectively we ignore or treat as error.
        genUiLogger.warning(
          'Invalid named argument format (missing colon): $segment',
        );
      }
    }

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
        processArg(argsStr.substring(start, i));
        start = i + 1;
      }
    }
    processArg(argsStr.substring(start));

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
