// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:json_schema_builder/json_schema_builder.dart';

import '../primitives/simple_items.dart';
import 'ui_models.dart' show A2uiValidationException;

/// Validates a set of A2UI components against a catalog [schema].
///
/// Throws [A2uiValidationException] on the first component that fails. State
/// is not rolled back.
void validateComponents({
  required String surfaceId,
  required Iterable<({String id, String type, JsonMap json})> components,
  required Schema schema,
}) {
  final List<Map<String, Object?>> allowedSchemas = _extractAllowedSchemas(
    jsonDecode(schema.toJson()) as Map<String, Object?>,
  );
  if (allowedSchemas.isEmpty) return;

  for (final component in components) {
    var matched = false;
    final errors = <String>[];

    for (final s in allowedSchemas) {
      if (_schemaMatchesType(s, component.type)) {
        try {
          _validateInstance(
            component.json,
            s,
            '/components/${component.id}',
            surfaceId,
          );
          matched = true;
          break;
        } catch (e) {
          errors.add(e.toString());
        }
      }
    }

    if (!matched) {
      if (errors.isNotEmpty) {
        throw A2uiValidationException(
          'Validation failed for component ${component.id} '
          '(${component.type}): ${errors.join("; ")}',
          surfaceId: surfaceId,
          path: '/components/${component.id}',
        );
      }
      throw A2uiValidationException(
        'Unknown component type: ${component.type}',
        surfaceId: surfaceId,
        path: '/components/${component.id}',
      );
    }
  }
}

List<Map<String, Object?>> _extractAllowedSchemas(
  Map<String, Object?> schemaMap,
) {
  if (schemaMap.containsKey('oneOf')) {
    return (schemaMap['oneOf'] as List).cast<Map<String, Object?>>();
  }
  if (schemaMap.containsKey('properties') &&
      (schemaMap['properties'] as Map).containsKey('components')) {
    final componentsProp =
        (schemaMap['properties'] as Map)['components'] as Map<String, Object?>;
    if (componentsProp.containsKey('items')) {
      final items = componentsProp['items'] as Map<String, Object?>;
      if (items.containsKey('oneOf')) {
        return (items['oneOf'] as List).cast<Map<String, Object?>>();
      }
      return [items];
    }
    if (componentsProp.containsKey('properties')) {
      return (componentsProp['properties'] as Map).values
          .cast<Map<String, Object?>>()
          .toList();
    }
  }
  return const [];
}

bool _schemaMatchesType(Map<String, Object?> schema, String type) {
  if (schema case {
    'properties': {'component': Map<String, Object?> compProp},
  }) {
    return switch (compProp) {
      {'const': String constType} when constType == type => true,
      {'enum': List<Object?> enums} when enums.contains(type) => true,
      _ => false,
    };
  }
  return false;
}

void _validateInstance(
  Object? instance,
  Map<String, Object?> schema,
  String path,
  String surfaceId,
) {
  if (instance == null) return;

  if (schema case {'const': Object? constVal} when instance != constVal) {
    throw A2uiValidationException(
      'Value mismatch. Expected $constVal, got $instance',
      surfaceId: surfaceId,
      path: path,
    );
  }
  if (schema case {
    'enum': List<Object?> enums,
  } when !enums.contains(instance)) {
    throw A2uiValidationException(
      'Value not in enum: $instance',
      surfaceId: surfaceId,
      path: path,
    );
  }
  if (schema case {'required': List<Object?> required} when instance is Map) {
    for (final String key in required.cast<String>()) {
      if (!instance.containsKey(key)) {
        throw A2uiValidationException(
          'Missing required property: $key',
          surfaceId: surfaceId,
          path: path,
        );
      }
    }
  }
  if (schema case {
    'properties': Map<String, Object?> props,
  } when instance is Map) {
    for (final MapEntry<String, Object?> entry in props.entries) {
      final String key = entry.key;
      final propSchema = entry.value as Map<String, Object?>;
      if (instance.containsKey(key)) {
        _validateInstance(instance[key], propSchema, '$path/$key', surfaceId);
      }
    }
  }
  if (schema case {
    'items': Map<String, Object?> itemsSchema,
  } when instance is List) {
    for (var i = 0; i < instance.length; i++) {
      _validateInstance(instance[i], itemsSchema, '$path/$i', surfaceId);
    }
  }
  if (schema case {'oneOf': List<Object?> oneOfs}) {
    var oneMatched = false;
    for (final Map<String, Object?> s in oneOfs.cast<Map<String, Object?>>()) {
      try {
        _validateInstance(instance, s, path, surfaceId);
        oneMatched = true;
        break;
      } catch (_) {}
    }
    if (!oneMatched) {
      throw A2uiValidationException(
        'Value did not match any oneOf schema',
        surfaceId: surfaceId,
        path: path,
      );
    }
  }
}
