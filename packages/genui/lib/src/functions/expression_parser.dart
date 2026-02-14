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

  static const int _maxRecursionDepth = 100;

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
    return _parseStringWithInterpolations(input, null);
  }

  /// Evaluates an expression which can be a String, Map (function call/path), etc.
  Object? evaluate(Object? expression) {
    if (expression is String) {
      return parse(expression);
    }
    if (expression is Map) {
      if (expression.containsKey('call')) {
        return evaluateFunctionCall(expression as JsonMap);
      }
      if (expression.containsKey('path')) {
        return _resolvePath(expression['path'] as String, null);
      }
    }
    return expression;
  }

  /// Extracts all data paths referenced in the given input.
  ///
  /// This method parses the input without evaluating functions, collecting
  /// all paths that would be accessed during evaluation.
  Set<DataPath> extractDependencies(String input) {
    if (!input.contains(r'${')) {
      return {};
    }
    final Set<DataPath> dependencies = {};
    _parseStringWithInterpolations(input, dependencies);
    return dependencies;
  }

  /// Extracts all data paths referenced in the given expression (String or
  /// Map).
  Set<DataPath> extractDependenciesFrom(Object? expression) {
    final Set<DataPath> dependencies = {};
    _extractDependenciesFrom(expression, dependencies);
    return dependencies;
  }

  void _extractDependenciesFrom(
    Object? expression,
    Set<DataPath> dependencies,
  ) {
    if (expression is String) {
      if (expression.contains(r'${')) {
        _parseStringWithInterpolations(expression, dependencies);
      }
    } else if (expression is Map) {
      if (expression.containsKey('path')) {
        dependencies.add(
          context.resolvePath(DataPath(expression['path'] as String)),
        );
      } else if (expression.containsKey('call')) {
        evaluateFunctionCall(expression as JsonMap, dependencies: dependencies);
      } else {
        // Recursively check values for other map types if necessary?
        // Usually expressions are structured strictly.
        // But functions args are maps.
        for (final Object? value in expression.values) {
          _extractDependenciesFrom(value, dependencies);
        }
      }
    } else if (expression is List) {
      for (final Object? item in expression) {
        _extractDependenciesFrom(item, dependencies);
      }
    }
  }

  /// Evaluates a dynamic boolean condition.
  ///
  /// The [condition] can be:
  /// - [bool]: Returns the boolean value directly.
  /// - [Map]:
  ///   - If it has a 'call' key, it is evaluated as a function call.
  ///   - If it has a 'path' key, it is evaluated as a data binding.
  /// - [String]: Parsed as an expression, then checked for truthiness.
  bool evaluateCondition(Object? condition) {
    if (condition == null) return false;
    if (condition is bool) return condition;

    Object? result;
    if (condition is String) {
      result = parse(condition);
    } else if (condition is Map) {
      if (condition.containsKey('call')) {
        result = evaluateFunctionCall(condition as JsonMap);
      } else if (condition.containsKey('path')) {
        result = _resolvePath(condition['path'] as String, null);
      } else {
        // Unknown map format, return false safely.
        return false;
      }
    } else {
      result = condition;
    }

    if (result is bool) return result;
    return result != null;
  }

  /// Evaluates a function call defined in [callDefinition].
  ///
  /// The [callDefinition] must contain a 'call' key with the function name
  /// and an optional 'args' key with a map of arguments.
  Object? evaluateFunctionCall(
    JsonMap callDefinition, {
    Set<DataPath>? dependencies,
  }) {
    final name = callDefinition['call'] as String?;
    if (name == null) {
      // Not a function call or missing 'call' property.
      return null;
    }

    final Map<String, Object?> args = {};
    final Object? argsJson = callDefinition['args'];

    if (argsJson is Map) {
      for (final Object? key in argsJson.keys) {
        final argName = key.toString();
        final Object? value = argsJson[key];
        if (value is String) {
          args[argName] = _parseStringWithInterpolations(value, dependencies);
        } else if (value is Map && value.containsKey('path')) {
          args[argName] = _resolvePath(value['path'] as String, dependencies);
        } else if (value is Map && value.containsKey('call')) {
          // Recursive evaluation for nested calls
          args[argName] = evaluateFunctionCall(
            value as JsonMap,
            dependencies: dependencies,
          );
        } else {
          args[argName] = value;
        }
      }
    } else if (argsJson != null) {
      genUiLogger.warning(
        'Function $name called with invalid args type: '
        '${argsJson.runtimeType}. Expected Map. Arguments dropped.',
      );
    }

    if (dependencies != null) {
      return null; // Don't execute function if collecting dependencies
    }

    return _functions.invoke(name, args);
  }

  Object? _parseStringWithInterpolations(
    String input,
    Set<DataPath>? dependencies,
  ) {
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

      final Object? value = _evaluateExpression(content, 0, dependencies);
      parts.add(value);

      i = endIndex + 1; // Skip closing '}'
    }

    if (parts.length == 1 && parts[0] is! String) {
      return parts[0];
    }

    if (dependencies != null) {
      return null;
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

  Object? _evaluateExpression(
    String content,
    int depth,
    Set<DataPath>? dependencies,
  ) {
    if (depth > _maxRecursionDepth) {
      genUiLogger.warning(
        'Max recursion depth reached in expression: $content',
      );
      return null;
    }

    content = content.trim();

    final RegExpMatch? match = RegExp(
      r'^([a-zA-Z0-9_]+)\s*\(',
    ).firstMatch(content);
    if (match != null && content.endsWith(')')) {
      final String funcName = match.group(1)!;
      final String argsStr = content.substring(match.end, content.length - 1);
      final Map<String, Object?> args = _parseNamedArgs(
        argsStr,
        depth + 1,
        dependencies,
      );

      if (dependencies != null) {
        return null;
      }
      return _functions.invoke(funcName, args);
    }

    return _resolvePath(content, dependencies);
  }

  Map<String, Object?> _parseNamedArgs(
    String argsStr,
    int depth,
    Set<DataPath>? dependencies,
  ) {
    final args = <String, Object?>{};
    var i = 0;

    while (i < argsStr.length) {
      // Skip whitespace
      while (i < argsStr.length && argsStr[i].trim().isEmpty) {
        i++;
      }
      if (i >= argsStr.length) break;

      // Expect key
      final keyStart = i;
      while (i < argsStr.length &&
          argsStr[i] != ':' &&
          argsStr[i] != ' ' &&
          argsStr[i] != ',') {
        i++;
      }
      final String key = argsStr.substring(keyStart, i).trim();

      // Skip whitespace after key
      while (i < argsStr.length && argsStr[i].trim().isEmpty) {
        i++;
      }

      // Expect colon
      if (i < argsStr.length && argsStr[i] == ':') {
        i++; // skip colon
      } else {
        genUiLogger.warning(
          'Invalid named argument format (missing colon) at index $i: $argsStr',
        );
        return args;
      }

      // Skip whitespace after colon
      while (i < argsStr.length && argsStr[i].trim().isEmpty) {
        i++;
      }

      // Parse Value
      final (Object? value, int nextIndex) = _parseValue(
        argsStr,
        i,
        depth,
        dependencies,
      );
      args[key] = value;
      i = nextIndex;

      // Skip whitespace after value
      while (i < argsStr.length && argsStr[i].trim().isEmpty) {
        i++;
      }

      // Expect comma or end
      if (i < argsStr.length && argsStr[i] == ',') {
        i++;
      }
    }
    return args;
  }

  (Object?, int) _parseValue(
    String input,
    int start,
    int depth,
    Set<DataPath>? dependencies,
  ) {
    if (start >= input.length) return (null, start);

    final String char = input[start];

    // String literal
    if (char == "'" || char == '"') {
      final quote = char;
      int i = start + 1;
      while (i < input.length) {
        if (input[i] == quote && input[i - 1] != r'\') {
          break;
        }
        i++;
      }
      if (i < input.length) {
        // Found closing quote
        final String val = input.substring(start + 1, i);
        // Recursively parse string for interpolations
        return (_parseStringWithInterpolations(val, dependencies), i + 1);
      }
      return (input.substring(start), input.length); // Unclosed string
    }

    // Expression ${...}
    if (char == r'$' && start + 1 < input.length && input[start + 1] == '{') {
      final (String content, int end) = _extractExpressionContent(
        input,
        start + 2,
      );
      if (end != -1) {
        final Object? val = _evaluateExpression(content, depth, dependencies);
        return (val, end + 1);
      }
    }

    // Heuristic for function calls REMOVED.
    // Arguments must be Literals (quoted strings, booleans, numbers)
    // or Nested Expressions (${...}).

    // Number / Boolean / Null / Path
    // Read the next token, stopping at delimiters like comma, parenthesis, or
    // brace. This allows `_parseNamedArgs` to handle the delimiters
    // appropriately.

    var i = start;
    while (i < input.length) {
      final String c = input[i];
      if (c == ',' ||
          c == ')' ||
          c == '}' ||
          c == ' ' ||
          c == '\t' ||
          c == '\n') {
        break;
      }
      i++;
    }

    final String token = input.substring(start, i);
    if (token == 'true') return (true, i);
    if (token == 'false') return (false, i);
    if (token == 'null') return (null, i);

    final num? numVal = num.tryParse(token);
    if (numVal != null) return (numVal, i);

    // Treat as a DataPath if no other type matches.
    return (_resolvePath(token, dependencies), i);
  }

  Object? _resolvePath(String pathStr, Set<DataPath>? dependencies) {
    pathStr = pathStr.trim();
    if (dependencies != null) {
      dependencies.add(context.resolvePath(DataPath(pathStr)));
      return null;
    }
    return context.getValue(pathStr);
  }
}
