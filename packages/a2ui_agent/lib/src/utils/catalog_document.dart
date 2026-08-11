// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_core/a2ui_core.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../primitives/protocol_version.dart';
import 'schema_utils.dart';

/// A [ComponentApi] backed by a schema loaded from a catalog document.
///
/// Agents describe and validate components they never render, so a loaded
/// catalog needs no Dart implementation behind each component.
class JsonComponentApi extends ComponentApi {
  @override
  final String name;

  @override
  final Schema schema;

  JsonComponentApi({required this.name, required this.schema});
}

/// A catalog function known only by its declaration.
///
/// Client functions execute on the renderer, so the agent side carries the
/// signature but cannot run it. [execute] throws to make an accidental
/// server-side invocation loud instead of silently wrong.
class DeclaredFunction extends FunctionImplementation {
  @override
  final String name;

  @override
  final A2uiReturnType returnType;

  @override
  final Schema argumentSchema;

  DeclaredFunction({
    required this.name,
    required this.returnType,
    required this.argumentSchema,
  });

  @override
  Object? execute(
    Map<String, dynamic> args,
    DataContext context, [
    CancellationSignal? cancellationSignal,
  ]) {
    throw UnsupportedError(
      "Catalog function '$name' is declaration-only on the agent side; it is "
      'executed by the renderer.',
    );
  }
}

/// Serializes [catalog] to an A2UI catalog document.
///
/// The result is the `{catalogId, components, functions, theme}` shape used by
/// inline catalogs and catalog files: each component schema is wrapped in the
/// standard component envelope, and `REF:` description markers used by
/// `package:a2ui_core` schemas are expanded back into JSON Schema `$ref`s.
Map<String, dynamic> catalogToDocument(Catalog<ComponentApi> catalog) {
  final components = <String, dynamic>{};
  for (final MapEntry<String, ComponentApi> entry
      in catalog.components.entries) {
    final Map<String, dynamic> schema = entry.value.schema.toJsonMap();
    expandSchemaRefs(schema);
    final Map<String, dynamic> flattened = _mergeAllOf(schema);
    components[entry.key] = {
      'allOf': [
        {r'$ref': r'common_types.json#/$defs/ComponentCommon'},
        {
          'properties': {
            'component': {'const': entry.key},
            ...?(flattened['properties'] as Map<String, dynamic>?),
          },
          'required': ['component', ...?(flattened['required'] as List?)],
        },
      ],
    };
  }

  final functions = <Map<String, dynamic>>[];
  for (final FunctionImplementation function in catalog.functions.values) {
    final Map<String, dynamic> parameters = function.argumentSchema.toJsonMap();
    expandSchemaRefs(parameters);
    functions.add({
      'name': function.name,
      'returnType': function.returnType.jsonValue,
      'parameters': parameters,
    });
  }

  Map<String, dynamic>? theme;
  if (catalog.themeSchema != null) {
    final Map<String, dynamic> themeSchema = catalog.themeSchema!.toJsonMap();
    expandSchemaRefs(themeSchema);
    theme = themeSchema['properties'] as Map<String, dynamic>?;
  }

  return {
    'catalogId': catalog.id,
    'components': components,
    if (functions.isNotEmpty) 'functions': functions,
    'theme': ?theme,
  };
}

/// Builds a [Catalog] from an A2UI catalog [document].
///
/// [protocolVersion] and [catalogId], when given, must agree with what the
/// document declares; a conflict throws [A2uiValidationError] rather than
/// silently loading a catalog the renderer did not ask for.
Catalog<ComponentApi> catalogFromDocument(
  Map<String, dynamic> document, {
  ProtocolVersion? protocolVersion,
  String? catalogId,
  String? source,
}) {
  final Object? declaredId = document['catalogId'];
  if (declaredId != null && declaredId is! String) {
    throw A2uiValidationError(
      "Catalog 'catalogId' must be a string.",
      details: source,
    );
  }
  if (catalogId != null && declaredId is String && declaredId != catalogId) {
    throw A2uiValidationError(
      "Catalog id mismatch: expected '$catalogId' but the document declares "
      "'$declaredId'.",
      details: source,
    );
  }

  final Object? declaredVersion = document['protocolVersion'];
  if (protocolVersion != null && declaredVersion is String) {
    final ProtocolVersion? parsed = ProtocolVersion.tryParse(declaredVersion);
    if (parsed != protocolVersion) {
      throw A2uiValidationError(
        'Protocol version mismatch: expected ${protocolVersion.wireValue} but '
        "the document declares '$declaredVersion'.",
        details: source,
      );
    }
  }

  final String id = (declaredId as String?) ?? catalogId ?? '';
  if (id.isEmpty) {
    throw A2uiValidationError(
      'Catalog document has no catalogId and none was supplied.',
      details: source,
    );
  }

  final Object? rawComponents = document['components'];
  if (rawComponents is! Map) {
    throw A2uiValidationError(
      "Catalog document must contain a 'components' object.",
      details: source,
    );
  }

  final components = <ComponentApi>[];
  for (final MapEntry<Object?, Object?> entry in rawComponents.entries) {
    final Object? name = entry.key;
    final Object? schema = entry.value;
    if (name is! String || schema is! Map) continue;
    components.add(
      JsonComponentApi(
        name: name,
        schema: Schema.fromMap(
          _stripComponentEnvelope(schema.cast<String, Object?>()),
        ),
      ),
    );
  }

  final functions = <FunctionImplementation>[];
  final Object? rawFunctions = document['functions'];
  if (rawFunctions is List) {
    for (final Object? entry in rawFunctions) {
      if (entry is! Map) continue;
      final Object? name = entry['name'];
      if (name is! String) continue;
      final Object? parameters = entry['parameters'];
      functions.add(
        DeclaredFunction(
          name: name,
          returnType: _parseReturnType(entry['returnType']),
          argumentSchema: parameters is Map
              ? Schema.fromMap(parameters.cast<String, Object?>())
              : Schema.object(properties: const {}),
        ),
      );
    }
  }

  final Object? theme = document['theme'];
  return Catalog<ComponentApi>(
    id: id,
    components: components,
    functions: functions,
    themeSchema: theme is Map
        ? Schema.object(properties: _themeProperties(theme))
        : null,
  );
}

/// Rewrites `REF:<pointer>|<description>` markers into JSON Schema `$ref`s.
///
/// `package:a2ui_core` encodes shared common-type references in schema
/// descriptions because its schema builder has no `$ref` constructor; catalog
/// documents use real references.
void expandSchemaRefs(Object? node) {
  if (node is! Map) return;

  final Object? description = node['description'];
  if (description is String && description.startsWith('REF:')) {
    final List<String> parts = description.substring(4).split('|');
    final String ref = parts.first;
    final String? actual = parts.length > 1 ? parts[1] : null;
    node.clear();
    node[r'$ref'] = ref;
    if (actual != null) node['description'] = actual;
    return;
  }

  for (final Object? value in node.values) {
    if (value is Map) {
      expandSchemaRefs(value);
    } else if (value is List) {
      for (final Object? item in value) {
        expandSchemaRefs(item);
      }
    }
  }
}

A2uiReturnType _parseReturnType(Object? value) {
  if (value is! String) return A2uiReturnType.any;
  if (value == A2uiReturnType.void_.jsonValue) return A2uiReturnType.void_;
  for (final type in A2uiReturnType.values) {
    if (type.name == value) return type;
  }
  return A2uiReturnType.any;
}

Map<String, Schema> _themeProperties(Map<Object?, Object?> theme) {
  final properties = <String, Schema>{};
  for (final MapEntry<Object?, Object?> entry in theme.entries) {
    final Object? key = entry.key;
    final Object? value = entry.value;
    if (key is String && value is Map) {
      properties[key] = Schema.fromMap(value.cast<String, Object?>());
    }
  }
  return properties;
}

/// Collapses `allOf` composition into a single properties/required pair.
Map<String, dynamic> _mergeAllOf(Map<String, dynamic> schema) {
  final ({Map<String, Schema> properties, Set<String> required}) flat =
      flattenSchemaProperties(Schema.fromMap(schema));
  return {
    'properties': <String, dynamic>{
      for (final MapEntry<String, Schema> entry in flat.properties.entries)
        entry.key: entry.value.value,
    },
    'required': flat.required.toList(),
  };
}

/// Removes the standard component envelope from a catalog document schema.
///
/// Catalog documents wrap every component as
/// `allOf: [ComponentCommon, {properties: {component: const, ...}}]`. Agents
/// work with the inner component API, so the envelope is peeled off on load;
/// [catalogToDocument] puts it back.
Map<String, Object?> _stripComponentEnvelope(Map<String, Object?> schema) {
  final Object? allOf = schema['allOf'];
  if (allOf is! List) return schema;

  final properties = <String, Object?>{};
  final required = <String>[];
  for (final Object? branch in allOf) {
    if (branch is! Map) continue;
    final Object? branchProperties = branch['properties'];
    if (branchProperties is Map) {
      for (final MapEntry<Object?, Object?> entry
          in branchProperties.entries) {
        final Object? key = entry.key;
        if (key is String && !envelopeKeys.contains(key)) {
          properties[key] = entry.value;
        }
      }
    }
    final Object? branchRequired = branch['required'];
    if (branchRequired is List) {
      for (final Object? name in branchRequired) {
        if (name is String && !envelopeKeys.contains(name)) required.add(name);
      }
    }
  }

  return {
    'type': 'object',
    'properties': properties,
    if (required.isNotEmpty) 'required': required,
  };
}
