// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_core/a2ui_core.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../parser/response_part.dart';
import '../../primitives/errors.dart';
import '../../utils/schema_utils.dart';
import 'constants.dart';
import 'lexer.dart';

/// Converts A2UI messages back into A2UI Express source.
///
/// Decompilation is the inverse of [ExpressCompiler](compiler.dart): the same
/// catalog signatures decide argument order, so a payload compiled from
/// Express decompiles to equivalent Express, which is what makes it practical
/// to author few-shot examples as ordinary A2UI JSON and show them to the
/// model in the compact syntax.
class ExpressDecompiler {
  /// The catalogs whose signatures drive argument ordering.
  final List<Catalog<ComponentApi>> catalogs;

  const ExpressDecompiler({required this.catalogs});

  /// Renders [messages] as Express source.
  String decompile(List<AgentToRendererMessage> messages) {
    final lines = <String>[];
    for (final message in messages) {
      switch (message) {
        case CreateSurfaceMessage():
          lines.add(
            '$expressSurfaceCall(${_string(message.surfaceId)}, '
            '${_string(message.catalogId)})',
          );
        case DeleteSurfaceMessage():
          lines.add('$expressDeleteSurfaceCall(${_string(message.surfaceId)})');
        case UpdateDataModelMessage():
          lines.add(
            r'$'
            '${message.path ?? '/'} = ${_plainValue(message.value)}',
          );
        case UpdateComponentsMessage():
          for (final Map<String, dynamic> component in message.components) {
            lines.add(_component(component));
          }
      }
    }
    return lines.join('\n');
  }

  String _component(Map<String, dynamic> component) {
    final Object? id = component['id'];
    final Object? type = component['component'];
    if (id is! String || type is! String) {
      throw A2uiFormatError(
        "Cannot decompile a component without an 'id' and a 'component' type.",
      );
    }
    if (!_isIdentifier(id)) {
      throw A2uiFormatError(
        "Component id '$id' is not a valid Express identifier, so it cannot "
        'be written as a variable assignment.',
      );
    }

    final ComponentApi? api = _componentApi(type);
    if (api == null) {
      throw A2uiFormatError(
        "Unknown component '$type'; it is not in the active catalogs.",
      );
    }

    final List<SignatureParameter> parameters = signatureOf(api.schema);
    final positional = <String>[];
    final named = <String>[];

    for (final parameter in parameters) {
      if (!component.containsKey(parameter.name)) {
        positional.add(expressSkipPlaceholder);
        continue;
      }
      positional.add(_value(component[parameter.name], parameter.schema));
    }
    while (positional.isNotEmpty && positional.last == expressSkipPlaceholder) {
      positional.removeLast();
    }

    for (final MapEntry<String, dynamic> entry in component.entries) {
      if (envelopeKeys.contains(entry.key)) continue;
      if (parameters.any((p) => p.name == entry.key)) continue;
      named.add('${entry.key}=${_plainValue(entry.value)}');
    }

    return '$id = $type(${[...positional, ...named].join(', ')})';
  }

  /// Renders a component property value, using [schema] to tell component
  /// references from ordinary strings.
  String _value(Object? value, Schema schema) {
    final String? ref = schemaRefName(schema);

    if (ref == 'ComponentId' && value is String) return value;

    if (ref == 'ChildList') {
      if (value is List) {
        final Iterable<String> children = value.map(
          (child) => child is String ? child : _plainValue(child),
        );
        return '[${children.join(', ')}]';
      }
      if (value is Map) {
        final Object? componentId = value['componentId'];
        final Object? path = value['path'];
        if (componentId is String && path is String) {
          return '$expressTemplateHelper(\$$path, $componentId)';
        }
      }
    }

    if (schema['items'] is Map && value is List) {
      final itemSchema = Schema.fromMap(
        (schema['items']! as Map).cast<String, Object?>(),
      );
      return '[${value.map((item) => _value(item, itemSchema)).join(', ')}]';
    }

    if (value is Map) {
      final String? check = _check(value);
      if (check != null) return check;
    }

    return _plainValue(value);
  }

  /// Renders a value that carries no schema context.
  String _plainValue(Object? value) {
    if (value == null) return 'null';
    if (value is String) return _string(value);
    if (value is num || value is bool) return '$value';
    if (value is List) {
      return '[${value.map(_plainValue).join(', ')}]';
    }
    if (value is Map) {
      final Map<String, dynamic> map = value.cast<String, dynamic>();

      final Object? path = map['path'];
      if (map.length == 1 && path is String) return '\$$path';

      final Object? event = map['event'];
      if (map.length == 1 && event is Map) {
        final Object? name = event['name'];
        final Object? context = event['context'];
        final String arguments = context is Map && context.isNotEmpty
            ? '${_string(name is String ? name : '')}, ${_plainValue(context)}'
            : _string(name is String ? name : '');
        return '$expressEventCall($arguments)';
      }

      final Object? functionCall = map['functionCall'];
      if (map.length == 1 && functionCall is Map) {
        return _plainValue(functionCall);
      }

      final Object? call = map['call'];
      if (call is String) return _functionCall(call, map['args']);

      final Iterable<String> entries = map.entries.map(
        (entry) => '${_key(entry.key)}: ${_plainValue(entry.value)}',
      );
      return '{${entries.join(', ')}}';
    }
    return _string('$value');
  }

  /// Renders a `Checkable` entry as `?name(args, "message")`.
  String? _check(Map<Object?, Object?> value) {
    final Object? condition = value['condition'];
    final Object? message = value['message'];
    if (condition is! Map || value.length != 2) return null;
    final Object? call = condition['call'];
    if (call is! String) return null;

    final List<String> arguments = _orderedArguments(call, condition['args']);
    if (message is String) arguments.add(_string(message));
    return arguments.isEmpty ? '?$call' : '?$call(${arguments.join(', ')})';
  }

  String _functionCall(String name, Object? args) =>
      '$name(${_orderedArguments(name, args).join(', ')})';

  /// Orders a function call's arguments by the catalog signature.
  List<String> _orderedArguments(String name, Object? args) {
    if (args is! Map) return [];
    final Map<String, dynamic> map = args.cast<String, dynamic>();
    final FunctionImplementation? function = _function(name);
    if (function == null) {
      return [
        for (final MapEntry<String, dynamic> entry in map.entries)
          '${entry.key}=${_plainValue(entry.value)}',
      ];
    }

    final List<SignatureParameter> parameters = signatureOf(
      function.argumentSchema,
    );
    final rendered = <String>[];
    for (final parameter in parameters) {
      if (!map.containsKey(parameter.name)) {
        rendered.add(expressSkipPlaceholder);
        continue;
      }
      rendered.add(_plainValue(map[parameter.name]));
    }
    while (rendered.isNotEmpty && rendered.last == expressSkipPlaceholder) {
      rendered.removeLast();
    }

    for (final MapEntry<String, dynamic> entry in map.entries) {
      if (parameters.any((p) => p.name == entry.key)) continue;
      rendered.add('${entry.key}=${_plainValue(entry.value)}');
    }
    return rendered;
  }

  String _key(String key) => _isIdentifier(key) ? key : _string(key);

  /// Quotes [value], preferring a raw string when escaping would obscure it.
  String _string(String value) {
    if (value.contains(r'\') && !value.contains('"') && !value.contains('\n')) {
      return 'r"$value"';
    }
    final String escaped = value
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"')
        .replaceAll('\n', r'\n')
        .replaceAll('\t', r'\t')
        .replaceAll('\r', r'\r');
    return '"$escaped"';
  }

  ComponentApi? _componentApi(String name) {
    for (final Catalog<ComponentApi> catalog in catalogs) {
      final ComponentApi? component = catalog.components[name];
      if (component != null) return component;
    }
    return null;
  }

  FunctionImplementation? _function(String name) {
    for (final Catalog<ComponentApi> catalog in catalogs) {
      final FunctionImplementation? function = catalog.functions[name];
      if (function != null) return function;
    }
    return null;
  }

  static bool _isIdentifier(String value) {
    if (value.isEmpty) return false;
    final List<ExpressToken> tokens;
    try {
      tokens = ExpressLexer(value).tokenize();
    } on A2uiFormatError {
      return false;
    }
    return tokens.length == 2 &&
        tokens.first.type == ExpressTokenType.identifier &&
        tokens.first.lexeme == value;
  }
}
