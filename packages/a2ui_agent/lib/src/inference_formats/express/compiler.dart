// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_core/a2ui_core.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../parser/response_part.dart';
import '../../primitives/errors.dart';
import '../../primitives/protocol_version.dart';
import '../../utils/schema_utils.dart';
import 'ast.dart';
import 'constants.dart';
import 'syntax_parser.dart';

/// Compiles A2UI Express statements into A2UI protocol messages.
///
/// A compiler instance is a session: it remembers the targeted surface, which
/// surfaces it has already created, and which component ids it has handed out,
/// so a document can be compiled all at once or statement by statement as it
/// streams in.
///
/// The compiler holds no knowledge of any particular catalog. Positional
/// arguments are mapped through [signatureOf], the same function the prompt
/// generator uses to describe components to the model.
///
/// Because `package:a2ui_core` models the `v0.9` envelopes, a compiled block
/// becomes `createSurface` (once per surface), then `updateDataModel` for data
/// assignments, then a single `updateComponents` carrying the flattened
/// adjacency list.
class ExpressCompiler {
  /// The catalogs component and function signatures are resolved against.
  final List<Catalog<ComponentApi>> catalogs;

  /// The surface used when a block does not call `surface(...)`.
  final String defaultSurfaceId;

  /// The protocol version stamped on emitted messages.
  final ProtocolVersion protocolVersion;

  final Set<String> _announcedSurfaces;
  final Set<String> _usedIds = {};

  String? _surfaceId;
  String? _catalogId;

  ExpressCompiler({
    required this.catalogs,
    this.defaultSurfaceId = expressDefaultSurfaceId,
    this.protocolVersion = ProtocolVersion.current,
    Set<String> existingSurfaceIds = const {},
  }) : _announcedSurfaces = {...existingSurfaceIds};

  /// The surface the compiler is currently targeting.
  String get surfaceId => _surfaceId ?? defaultSurfaceId;

  /// Compiles a complete Express document.
  List<AgentToRendererMessage> compile(String source) =>
      compileStatements(ExpressSyntaxParser.fromSource(source).parseProgram());

  /// Compiles [statements], continuing the current session.
  List<AgentToRendererMessage> compileStatements(
    List<ExpressStatement> statements,
  ) {
    final messages = <AgentToRendererMessage>[];
    final components = <Map<String, dynamic>>[];

    void flushComponents() {
      if (components.isEmpty) return;
      _ensureSurface(messages);
      messages.add(
        UpdateComponentsMessage(
          version: protocolVersion.wireValue,
          surfaceId: surfaceId,
          components: List<Map<String, dynamic>>.from(components),
        ),
      );
      components.clear();
    }

    for (final statement in statements) {
      switch (statement) {
        case CallStatement(call: final CallExpression call):
          _compileCallStatement(call, messages, flushComponents);
        case DataAssignment(
          path: final String path,
          value: final ExpressExpression value,
        ):
          _ensureSurface(messages);
          messages.add(
            UpdateDataModelMessage(
              version: protocolVersion.wireValue,
              surfaceId: surfaceId,
              path: path,
              value: _compileDataValue(value),
            ),
          );
        case VariableAssignment(
          name: final String name,
          value: final ExpressExpression value,
        ):
          components.addAll(_compileAssignment(name, value));
      }
    }

    flushComponents();
    return messages;
  }

  void _compileCallStatement(
    CallExpression call,
    List<AgentToRendererMessage> messages,
    void Function() flushComponents,
  ) {
    switch (call.name) {
      case expressSurfaceCall:
        final List<ExpressExpression> args = call.positional;
        if (args.isEmpty) {
          throw A2uiFormatError(
            'surface() needs a surface id.',
            line: call.line,
          );
        }
        flushComponents();
        _surfaceId = _requireString(args.first, 'surface id');
        if (args.length > 1) {
          _catalogId = _requireString(args[1], 'catalog id');
        }
      case expressDeleteSurfaceCall:
        final List<ExpressExpression> args = call.positional;
        flushComponents();
        final String target = args.isEmpty
            ? surfaceId
            : _requireString(args.first, 'surface id');
        messages.add(
          DeleteSurfaceMessage(
            version: protocolVersion.wireValue,
            surfaceId: target,
          ),
        );
        _announcedSurfaces.remove(target);
      default:
        throw A2uiFormatError(
          "Standalone call '${call.name}()' compiles to a callFunction RPC "
          'message, which the v0.9 protocol modelled by package:a2ui_core '
          'does not define. Use surface(), deleteSurface(), or move the call '
          'into a component property.',
          line: call.line,
        );
    }
  }

  void _ensureSurface(List<AgentToRendererMessage> messages) {
    final String id = surfaceId;
    if (!_announcedSurfaces.add(id)) return;
    messages.add(
      CreateSurfaceMessage(
        version: protocolVersion.wireValue,
        surfaceId: id,
        catalogId: _catalogId ?? _defaultCatalogId(),
      ),
    );
  }

  String _defaultCatalogId() {
    if (catalogs.isEmpty) {
      throw A2uiFormatError(
        'Cannot compile Express without a catalog: the compiler needs '
        'component signatures to map positional arguments, and a catalog id '
        'for createSurface.',
      );
    }
    return catalogs.first.id;
  }

  List<Map<String, dynamic>> _compileAssignment(
    String name,
    ExpressExpression value,
  ) {
    if (value is! CallExpression) {
      throw A2uiFormatError(
        "'$name' must be assigned a component, for example "
        '$name = Text("Hello").',
        line: value.line,
      );
    }
    _usedIds.add(name);
    final sink = <Map<String, dynamic>>[];
    final Map<String, dynamic> component = _compileComponent(
      name,
      value,
      sink,
    );
    return [component, ...sink];
  }

  /// Compiles [call] into a component map, appending inline children to
  /// [sink].
  ///
  /// The parent is returned rather than appended so that callers can keep
  /// parents ahead of their children: the renderer builds the tree in the
  /// order it receives it.
  Map<String, dynamic> _compileComponent(
    String id,
    CallExpression call,
    List<Map<String, dynamic>> sink,
  ) {
    final ComponentApi api = _requireComponent(call.name, call.line);
    final List<SignatureParameter> parameters = signatureOf(api.schema);
    final properties = <String, dynamic>{};

    final List<ExpressExpression> positional = call.positional;
    if (positional.length > parameters.length) {
      throw A2uiFormatError(
        '${api.name} takes ${parameters.length} argument(s) but '
        '${positional.length} were given. Signature: '
        '${api.name}(${parameters.map((p) => p.label).join(', ')}).',
        line: call.line,
      );
    }

    for (var index = 0; index < positional.length; index++) {
      final ExpressExpression argument = positional[index];
      if (argument is SkippedExpression) continue;
      final SignatureParameter parameter = parameters[index];
      properties[parameter.name] = _compileValue(
        argument,
        parameter.schema,
        parentId: id,
        property: parameter.name,
        sink: sink,
      );
    }

    for (final MapEntry<String, ExpressExpression> entry
        in call.named.entries) {
      final SignatureParameter? parameter = _parameterNamed(
        parameters,
        entry.key,
      );
      if (parameter == null) {
        throw A2uiFormatError(
          "${api.name} has no parameter '${entry.key}'. Signature: "
          '${api.name}(${parameters.map((p) => p.label).join(', ')}).',
          line: entry.value.line,
        );
      }
      properties[parameter.name] = _compileValue(
        entry.value,
        parameter.schema,
        parentId: id,
        property: parameter.name,
        sink: sink,
      );
    }

    for (final parameter in parameters) {
      if (parameter.isRequired && !properties.containsKey(parameter.name)) {
        throw A2uiFormatError(
          "${api.name} is missing required argument '${parameter.name}'. "
          'Signature: '
          '${api.name}(${parameters.map((p) => p.label).join(', ')}).',
          line: call.line,
        );
      }
    }

    return {'id': id, 'component': api.name, ...properties};
  }

  Object? _compileValue(
    ExpressExpression expression,
    Schema schema, {
    required String parentId,
    required String property,
    required List<Map<String, dynamic>> sink,
  }) {
    final String? ref = schemaRefName(schema);

    switch (expression) {
      case SkippedExpression():
        return null;
      case LiteralExpression(value: final Object? value):
        return value;
      case PathExpression(path: final String path):
        return {'path': path};
      case VariableExpression(name: final String name):
        if (ref == 'ChildList') return [name];
        return name;
      case ArrayExpression(items: final List<ExpressExpression> items):
        if (ref == 'ChildList') {
          return [
            for (var index = 0; index < items.length; index++)
              _childId(
                items[index],
                parentId: parentId,
                property: property,
                index: index,
                sink: sink,
              ),
          ];
        }
        final Schema itemSchema = _itemSchema(schema);
        return [
          for (final ExpressExpression item in items)
            _compileValue(
              item,
              itemSchema,
              parentId: parentId,
              property: property,
              sink: sink,
            ),
        ];
      case MapExpression(entries: final Map<String, ExpressExpression> entries):
        return {
          for (final MapEntry<String, ExpressExpression> entry
              in entries.entries)
            entry.key: _compileValue(
              entry.value,
              _propertySchema(schema, entry.key),
              parentId: parentId,
              property: property,
              sink: sink,
            ),
        };
      case CheckExpression():
        return _compileCheck(expression);
      case CallExpression():
        return _compileCall(
          expression,
          ref: ref,
          parentId: parentId,
          property: property,
          sink: sink,
        );
    }
  }

  Object? _compileCall(
    CallExpression call, {
    required String? ref,
    required String parentId,
    required String property,
    required List<Map<String, dynamic>> sink,
  }) {
    if (call.name == expressTemplateHelper) {
      final List<ExpressExpression> args = call.positional;
      if (args.length != 2) {
        throw A2uiFormatError(
          '$expressTemplateHelper(path, component) takes exactly two '
          'arguments.',
          line: call.line,
        );
      }
      final ExpressExpression pathArgument = args.first;
      if (pathArgument is! PathExpression) {
        throw A2uiFormatError(
          'The first argument of $expressTemplateHelper must be a data path, '
          r'for example $/items.',
          line: call.line,
        );
      }
      return {
        'componentId': _childId(
          args[1],
          parentId: parentId,
          property: property,
          index: 0,
          sink: sink,
        ),
        'path': pathArgument.path,
      };
    }

    if (call.name == expressEventCall) {
      final List<ExpressExpression> args = call.positional;
      if (args.isEmpty) {
        throw A2uiFormatError(
          '$expressEventCall() needs an event name.',
          line: call.line,
        );
      }
      final context = <String, dynamic>{};
      if (args.length > 1) {
        final ExpressExpression contextArgument = args[1];
        if (contextArgument is! MapExpression) {
          throw A2uiFormatError(
            'The second argument of $expressEventCall must be a map, for '
            r'example {rep: $/form/rep}.',
            line: call.line,
          );
        }
        for (final MapEntry<String, ExpressExpression> entry
            in contextArgument.entries.entries) {
          context[entry.key] = _compileDataValue(entry.value);
        }
      }
      return {
        'event': {
          'name': _requireString(args.first, 'event name'),
          'context': context,
        },
      };
    }

    final ComponentApi? component = _componentApi(call.name);
    if (component != null) {
      final String id = _generateId(parentId, property);
      _appendInline(id, call, sink);
      return ref == 'ChildList' ? [id] : id;
    }

    final FunctionImplementation function = _requireFunction(
      call.name,
      call.line,
    );
    return _compileFunctionCall(call, function);
  }

  Map<String, dynamic> _compileFunctionCall(
    CallExpression call,
    FunctionImplementation function,
  ) {
    return {
      'call': function.name,
      'args': _mapFunctionArguments(call, function),
      'returnType': function.returnType.jsonValue,
    };
  }

  Map<String, dynamic> _mapFunctionArguments(
    CallExpression call,
    FunctionImplementation function, {
    int dropTrailing = 0,
  }) {
    final List<SignatureParameter> parameters = signatureOf(
      function.argumentSchema,
    );
    final List<ExpressExpression> positional = call.positional;
    final int count = positional.length - dropTrailing;
    if (count > parameters.length) {
      throw A2uiFormatError(
        '${function.name} takes ${parameters.length} argument(s) but $count '
        'were given. Signature: '
        '${function.name}(${parameters.map((p) => p.label).join(', ')}).',
        line: call.line,
      );
    }

    final args = <String, dynamic>{};
    for (var index = 0; index < count; index++) {
      final ExpressExpression argument = positional[index];
      if (argument is SkippedExpression) continue;
      args[parameters[index].name] = _compileDataValue(argument);
    }
    for (final MapEntry<String, ExpressExpression> entry
        in call.named.entries) {
      if (_parameterNamed(parameters, entry.key) == null) {
        throw A2uiFormatError(
          "${function.name} has no parameter '${entry.key}'.",
          line: entry.value.line,
        );
      }
      args[entry.key] = _compileDataValue(entry.value);
    }
    return args;
  }

  /// Compiles `?name(args...)` into a `Checkable` entry.
  ///
  /// A check carries both a condition and the message shown when it fails.
  /// Arguments map onto the catalog function's own signature; one extra
  /// trailing argument is taken as the failure message, which is what
  /// `?regex("^[0-9]{5}$", "Must be a zip code")` means.
  Map<String, dynamic> _compileCheck(CheckExpression check) {
    final FunctionImplementation function = _requireFunction(
      check.name,
      check.line,
    );
    final List<SignatureParameter> parameters = signatureOf(
      function.argumentSchema,
    );
    final bool hasMessage = check.arguments.length > parameters.length;
    final String message = hasMessage
        ? _requireString(check.arguments.last, 'check message')
        : 'Failed check: ${check.name}';

    final call = CallExpression(check.line, check.name, [
      for (final ExpressExpression argument in check.arguments)
        ExpressArgument(value: argument),
    ]);

    return {
      'condition': {
        'call': function.name,
        'args': _mapFunctionArguments(
          call,
          function,
          dropTrailing: hasMessage ? 1 : 0,
        ),
        'returnType': A2uiReturnType.boolean.jsonValue,
      },
      'message': message,
    };
  }

  /// Compiles an expression used as plain data rather than as a component
  /// property.
  Object? _compileDataValue(ExpressExpression expression) {
    switch (expression) {
      case LiteralExpression(value: final Object? value):
        return value;
      case PathExpression(path: final String path):
        return {'path': path};
      case SkippedExpression():
        return null;
      case VariableExpression(name: final String name):
        return name;
      case ArrayExpression(items: final List<ExpressExpression> items):
        return [
          for (final ExpressExpression item in items) _compileDataValue(item),
        ];
      case MapExpression(entries: final Map<String, ExpressExpression> entries):
        return {
          for (final MapEntry<String, ExpressExpression> entry
              in entries.entries)
            entry.key: _compileDataValue(entry.value),
        };
      case CheckExpression():
        return _compileCheck(expression);
      case CallExpression():
        if (expression.name == expressEventCall) {
          return _compileCall(
            expression,
            ref: null,
            parentId: '',
            property: '',
            sink: <Map<String, dynamic>>[],
          );
        }
        return _compileFunctionCall(
          expression,
          _requireFunction(expression.name, expression.line),
        );
    }
  }

  String _childId(
    ExpressExpression expression, {
    required String parentId,
    required String property,
    required int index,
    required List<Map<String, dynamic>> sink,
  }) {
    switch (expression) {
      case VariableExpression(name: final String name):
        return name;
      case LiteralExpression(value: final Object? value) when value is String:
        return value;
      case CallExpression():
        final String id = _generateId(parentId, property, index: index);
        _appendInline(id, expression, sink);
        return id;
      default:
        throw A2uiFormatError(
          'A child must be a component variable or an inline component.',
          line: expression.line,
        );
    }
  }

  /// Compiles an inline component and appends it to [sink] ahead of its own
  /// inline descendants.
  ///
  /// Descendants are gathered into a local sink first so the finished
  /// component can be placed before them: the streaming renderer requires
  /// every parent to arrive before its children.
  void _appendInline(
    String id,
    CallExpression call,
    List<Map<String, dynamic>> sink,
  ) {
    final descendants = <Map<String, dynamic>>[];
    final Map<String, dynamic> compiled = _compileComponent(
      id,
      call,
      descendants,
    );
    sink
      ..add(compiled)
      ..addAll(descendants);
  }


  String _generateId(String parentId, String property, {int? index}) {
    final base = index == null
        ? '${parentId}_$property'
        : '${parentId}_$property$index';
    var candidate = base;
    var suffix = 2;
    while (!_usedIds.add(candidate)) {
      candidate = '$base$suffix';
      suffix++;
    }
    return candidate;
  }

  SignatureParameter? _parameterNamed(
    List<SignatureParameter> parameters,
    String name,
  ) {
    for (final parameter in parameters) {
      if (parameter.name == name) return parameter;
    }
    return null;
  }

  Schema _itemSchema(Schema schema) {
    final Object? items = schema['items'];
    if (items is Map) return Schema.fromMap(items.cast<String, Object?>());
    return Schema.fromMap(const {});
  }

  Schema _propertySchema(Schema schema, String property) {
    final ({Map<String, Schema> properties, Set<String> required}) flat =
        flattenSchemaProperties(schema);
    return flat.properties[property] ?? Schema.fromMap(const {});
  }

  ComponentApi? _componentApi(String name) {
    if (expressReservedNames.contains(name)) return null;
    for (final Catalog<ComponentApi> catalog in catalogs) {
      final ComponentApi? component = catalog.components[name];
      if (component != null) return component;
    }
    return null;
  }

  ComponentApi _requireComponent(String name, int line) {
    final ComponentApi? component = _componentApi(name);
    if (component != null) return component;
    throw A2uiFormatError(
      "Unknown component '$name'. The active catalogs define: "
      '${_componentNames().join(', ')}.',
      line: line,
    );
  }

  FunctionImplementation _requireFunction(String name, int line) {
    for (final Catalog<ComponentApi> catalog in catalogs) {
      final FunctionImplementation? function = catalog.functions[name];
      if (function != null) return function;
    }
    throw A2uiFormatError(
      "Unknown function '$name'. The active catalogs define: "
      '${_functionNames().join(', ')}.',
      line: line,
    );
  }

  String _requireString(ExpressExpression expression, String what) {
    if (expression is LiteralExpression && expression.value is String) {
      return expression.value! as String;
    }
    throw A2uiFormatError(
      'Expected a string for the $what.',
      line: expression.line,
    );
  }

  List<String> _componentNames() => [
    for (final Catalog<ComponentApi> catalog in catalogs)
      ...catalog.components.keys,
  ];

  List<String> _functionNames() => [
    for (final Catalog<ComponentApi> catalog in catalogs)
      ...catalog.functions.keys,
  ];
}
