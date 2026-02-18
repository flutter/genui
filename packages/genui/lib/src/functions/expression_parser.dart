// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:rxdart/rxdart.dart';

import '../interfaces/client_function.dart' as cf;
import '../model/data_model.dart';
import '../primitives/logging.dart';
import '../primitives/simple_items.dart';

class RecursionExpectedException implements Exception {
  RecursionExpectedException(this.message);
  final String message;
  @override
  String toString() => 'RecursionExpectedException: $message';
}

/// Parses and evaluates expressions in the A2UI `${expression}` format.
class ExpressionParser {
  ExpressionParser(this.context);

  final DataContext context;

  static const int _maxRecursionDepth = 100;

  /// Parses the input string and resolves any embedded expressions.
  ///
  /// If the string contains a single expression that encompasses the entire
  /// string (e.g. "${/foo}"), the return value may be of any type (not just
  /// [String]), and may be a [Stream] if the expression involves a reactive
  /// function.
  ///
  /// If the string contains text mixed with expressions (e.g. "Value: ${/foo}"),
  /// the return value will always be a [String] (or a [Stream<String>]).
  ///
  /// This method is the entry point for expression resolution. It handles
  /// escaping of the `${` sequence using a backslash (e.g. `\${`).
  // parse method removed here, using the one with asStream support below

  /// Evaluates an expression and returns a [Stream] of the result.
  Stream<Object?> evaluateStream(Object? expression) {
    // If expression is static (no interpolation/paths), return Stream.value
    if (expression == null) return Stream.value(null);
    if (expression is! String && expression is! Map) {
      return Stream.value(expression);
    }

    // Use common logic but prefer streams
    final Object? result = _evaluate(expression, asStream: true);
    if (result is Stream) {
      return result.cast<Object?>();
    }
    return Stream.value(result);
  }

  /// Evaluates an expression which can be a String, Map (function call/path), etc.
  Object? evaluate(Object? expression) {
    return _evaluate(expression, asStream: false);
  }

  Object? _evaluate(
    Object? expression, {
    required bool asStream,
    int depth = 0,
  }) {
    if (depth > _maxRecursionDepth) {
      throw RecursionExpectedException(
        'Max recursion depth reached in _evaluate',
      );
    }

    if (expression is String) {
      return parse(expression, asStream: asStream, depth: depth + 1);
    }
    if (expression is Map) {
      if (expression.containsKey('call')) {
        return evaluateFunctionCall(
          expression as JsonMap,
          asStream: asStream,
          depth: depth + 1,
        );
      }
      if (expression.containsKey('path')) {
        return _resolvePath(
          expression['path'] as String,
          null,
          asStream: asStream,
        );
      }
    }
    return expression;
  }

  /// Parses the input string and resolves any embedded expressions.
  Object? parse(String input, {bool asStream = false, int depth = 0}) {
    if (depth > _maxRecursionDepth) {
      throw RecursionExpectedException('Max recursion depth reached in parse');
    }

    if (!input.contains(r'${')) {
      return asStream ? Stream.value(input) : input;
    }
    return _parseStringWithInterpolations(
      input,
      null,
      asStream: asStream,
      depth: depth + 1,
    );
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
    _parseStringWithInterpolations(input, dependencies, depth: 0);
    return dependencies;
  }

  /// Extracts all data paths referenced in the given expression (String or
  /// Map).
  Set<DataPath> extractDependenciesFrom(Object? expression) {
    final Set<DataPath> dependencies = {};
    _extractDependenciesFrom(expression, dependencies, depth: 0);
    return dependencies;
  }

  void _extractDependenciesFrom(
    Object? expression,
    Set<DataPath> dependencies, {
    required int depth,
  }) {
    if (depth > _maxRecursionDepth) {
      throw RecursionExpectedException(
        'Max recursion depth reached in dependency extraction.',
      );
    }

    if (expression is String) {
      if (expression.contains(r'${')) {
        _parseStringWithInterpolations(expression, dependencies, depth: depth);
      }
    } else if (expression is Map) {
      if (expression.containsKey('path')) {
        dependencies.add(
          context.resolvePath(DataPath(expression['path'] as String)),
        );
      } else if (expression.containsKey('call')) {
        evaluateFunctionCall(
          expression as JsonMap,
          dependencies: dependencies,
          depth: depth + 1,
        );
      } else {
        for (final Object? value in expression.values) {
          _extractDependenciesFrom(value, dependencies, depth: depth + 1);
        }
      }
    } else if (expression is List) {
      for (final Object? item in expression) {
        _extractDependenciesFrom(item, dependencies, depth: depth + 1);
      }
    }
  }

  /// Evaluates a dynamic boolean condition and returns a [Stream<bool>].
  ///
  /// This is the reactive version of [evaluateConditionSync]. It should be used
  /// when the condition might depend on reactive data sources or functions.
  Stream<bool> evaluateConditionStream(Object? condition) {
    if (condition == null) return Stream.value(false);
    if (condition is bool) return Stream.value(condition);

    Object? result;
    if (condition is String) {
      result = parse(condition, asStream: true);
    } else if (condition is Map) {
      if (condition.containsKey('call')) {
        result = evaluateFunctionCall(condition as JsonMap, asStream: true);
      } else if (condition.containsKey('path')) {
        result = _resolvePath(
          condition['path'] as String,
          null,
          asStream: true,
        );
      } else {
        return Stream.value(false);
      }
    } else {
      result = condition;
    }

    if (result is Stream) {
      return result.map((v) {
        if (v is bool) return v;
        return v != null;
      });
    }

    if (result is bool) return Stream.value(result);
    return Stream.value(result != null);
  }

  /// Evaluates a dynamic boolean condition.
  ///
  /// The [condition] can be:
  /// - [bool]: Returns the boolean value directly.
  /// - [Map]:
  ///   - If it has a 'call' key, it is evaluated as a function call.
  ///   - If it has a 'path' key, it is evaluated as a data binding.
  /// - [String]: Parsed as an expression, then checked for truthiness.
  ///
  /// **Note:** If the condition evaluates to a [Stream], this method currently
  /// checks if the stream itself is non-null (truthy), creating a static check.
  /// For reactive boolean checks, you should consume the result of [evaluate]
  /// and listen to the stream.
  bool evaluateConditionSync(Object? condition) {
    if (condition == null) return false;
    if (condition is bool) return condition;

    Object? result;
    if (condition is String) {
      result = parse(condition, asStream: true);
    } else if (condition is Map) {
      if (condition.containsKey('call')) {
        result = evaluateFunctionCall(condition as JsonMap, asStream: true);
      } else if (condition.containsKey('path')) {
        result = _resolvePath(
          condition['path'] as String,
          null,
          asStream: true,
        );
      } else {
        return false;
      }
    } else {
      result = condition;
    }

    if (result is bool) return result;
    // Streams are truthy references, but that's probably not what we want
    // for conditional rendering if we want *reactive* conditions.
    // However, this method is synchronous.
    return result != null;
  }

  /// Evaluates a function call defined in [callDefinition].
  ///
  /// The [callDefinition] must contain a 'call' key with the function name
  /// and an optional 'args' key with a map of arguments.
  Object? evaluateFunctionCall(
    JsonMap callDefinition, {
    Set<DataPath>? dependencies,
    bool asStream = false,
    int depth = 0,
  }) {
    if (depth > _maxRecursionDepth) {
      throw RecursionExpectedException(
        'Max recursion depth reached in evaluateFunctionCall',
      );
    }

    final name = callDefinition['call'] as String?;
    if (name == null) {
      return asStream ? Stream.value(null) : null;
    }

    // 1. Resolve arguments
    final Map<String, Object?> args = {};
    final Object? argsJson = callDefinition['args'];
    var hasStreams = false;

    if (argsJson is Map) {
      for (final Object? key in argsJson.keys) {
        final argName = key.toString();
        final Object? value = argsJson[key];
        Object? resolvedValue;

        if (value is String) {
          resolvedValue = _parseStringWithInterpolations(
            value,
            dependencies,
            asStream: asStream,
            depth: depth + 1,
          );
        } else if (value is Map && value.containsKey('path')) {
          resolvedValue = _resolvePath(
            value['path'] as String,
            dependencies,
            asStream: asStream,
          );
        } else if (value is Map && value.containsKey('call')) {
          resolvedValue = evaluateFunctionCall(
            value as JsonMap,
            dependencies: dependencies,
            asStream: asStream,
            depth: depth + 1,
          );
        } else {
          resolvedValue = value;
        }

        if (resolvedValue is Stream) {
          hasStreams = true;
        }
        args[argName] = resolvedValue;
      }
    } else if (argsJson != null) {
      genUiLogger.warning(
        'Function $name called with invalid args type: '
        '${argsJson.runtimeType}. Expected Map. Arguments dropped.',
      );
    }

    if (dependencies != null) {
      return null; // Dependency collection only
    }

    final cf.ClientFunction? func = context.getFunction(name);
    if (func == null) {
      genUiLogger.warning('Function not found: $name');
      return asStream ? Stream.value(null) : null;
    }

    // 2. Execute function
    if (!hasStreams) {
      // Synchronous execution (returns Stream, but args are static)
      final Stream<Object?> result = func.execute(args, context);
      if (asStream) {
        return Stream.value(result);
      }
      return result;
    }

    // 3. Handle Stream arguments
    // Create a stream that combines all argument streams, then switches to the
    // result of execution.
    final List<String> keys = args.keys.toList();
    final List<Stream<Object?>> streams = keys.map((key) {
      final Object? val = args[key];
      if (val is Stream) return val.cast<Object?>();
      return Stream<Object?>.value(val);
    }).toList();

    return CombineLatestStream.list(streams).switchMap((List<Object?> values) {
      final Map<String, Object?> combinedArgs = {};
      for (var i = 0; i < keys.length; i++) {
        combinedArgs[keys[i]] = values[i];
      }
      final Stream<Object?> result = func.execute(combinedArgs, context);
      return result.cast<Object?>();
      // return Stream<Object?>.value(result); // Dead code removed too
    });
  }

  Object? _parseStringWithInterpolations(
    String input,
    Set<DataPath>? dependencies, {
    bool asStream = false,
    int depth = 0,
  }) {
    if (depth > _maxRecursionDepth) {
      throw RecursionExpectedException(
        'Max recursion depth reached in _parseStringWithInterpolations',
      );
    }

    var i = 0;
    final parts = <Object?>[];
    var hasStreams = false;

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

      final Object? value = _evaluateExpression(
        content,
        depth + 1,
        dependencies,
      );
      if (value is Stream) {
        hasStreams = true;
      }
      parts.add(value);

      i = endIndex + 1; // Skip closing '}'
    }

    if (parts.isEmpty) return '';

    if (parts.length == 1 && parts[0] is! String) {
      return parts[0];
    }

    if (dependencies != null) {
      return null;
    }

    if (!hasStreams && !asStream) {
      return parts.map((e) => e?.toString() ?? '').join('');
    }

    // Combine streams for string interpolation
    final List<Stream<Object?>> streams = parts.map((part) {
      if (part is Stream) return part.cast<Object?>();
      return Stream<Object?>.value(part);
    }).toList();

    return CombineLatestStream.list(streams).map((List<Object?> values) {
      return values.map((e) => e?.toString() ?? '').join('');
    });
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
      throw RecursionExpectedException(
        'Max recursion depth reached in expression: $content',
      );
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

      // Construct a call definition for evaluateFunctionCall to reuse logic
      return evaluateFunctionCall({'call': funcName, 'args': args});
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
      while (i < argsStr.length && argsStr[i].trim().isEmpty) {
        i++;
      }
      if (i >= argsStr.length) break;

      final keyStart = i;
      while (i < argsStr.length &&
          argsStr[i] != ':' &&
          argsStr[i] != ' ' &&
          argsStr[i] != ',') {
        i++;
      }
      final String key = argsStr.substring(keyStart, i).trim();

      while (i < argsStr.length && argsStr[i].trim().isEmpty) {
        i++;
      }

      if (i < argsStr.length && argsStr[i] == ':') {
        i++;
      } else {
        genUiLogger.warning(
          'Invalid named argument format (missing colon) at index $i: $argsStr',
        );
        return args;
      }

      while (i < argsStr.length && argsStr[i].trim().isEmpty) {
        i++;
      }

      final (Object? value, int nextIndex) = _parseValue(
        argsStr,
        i,
        depth,
        dependencies,
      );
      args[key] = value;
      i = nextIndex;

      while (i < argsStr.length && argsStr[i].trim().isEmpty) {
        i++;
      }

      if (i < argsStr.length && argsStr[i] == ',') i++;
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
        final String val = input.substring(start + 1, i);
        return (
          _parseStringWithInterpolations(val, dependencies, depth: depth + 1),
          i + 1,
        );
      }
      return (input.substring(start), input.length);
    }

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

    return (_resolvePath(token, dependencies), i);
  }

  Object? _resolvePath(
    String pathStr,
    Set<DataPath>? dependencies, {
    bool asStream = false,
  }) {
    pathStr = pathStr.trim();
    if (dependencies != null) {
      dependencies.add(context.resolvePath(DataPath(pathStr)));
      return null;
    }
    if (asStream) {
      return context.subscribeStream<Object?>(pathStr);
    }
    return context.getValue(pathStr);
  }
}
