// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_schema/json_schema.dart';
import 'package:json_schema_builder/json_schema_builder.dart' as jsb;

/// An error that occurred during schema adaptation.
///
/// This class encapsulates information about an error that occurred while
/// converting a `json_schema_builder` schema to a dartantic_ai JsonSchema.
class DartanticSchemaAdapterError {
  /// Creates a [DartanticSchemaAdapterError].
  ///
  /// The [message] describes the error, and the [path] indicates where in the
  /// schema the error occurred.
  DartanticSchemaAdapterError(this.message, {required this.path});

  /// A message describing the error.
  final String message;

  /// The path to the location in the schema where the error occurred.
  final List<String> path;

  @override
  String toString() => 'Error at path "${path.join('/')}": $message';
}

/// The result of a schema adaptation.
///
/// This class holds the result of a schema conversion, including the adapted
/// schema and any errors that occurred during the process.
class DartanticSchemaAdapterResult {
  /// Creates a [DartanticSchemaAdapterResult].
  ///
  /// The [schema] is the result of the adaptation, and [errors] is a list of
  /// any errors that were encountered.
  DartanticSchemaAdapterResult(this.schema, this.errors);

  /// The adapted schema.
  ///
  /// This may be null if the schema could not be adapted at all.
  final JsonSchema? schema;

  /// A list of errors that occurred during adaptation.
  final List<DartanticSchemaAdapterError> errors;
}

/// An adapter to convert a [jsb.Schema] from the `json_schema_builder` package
/// to a [JsonSchema] from the `json_schema` package.
///
/// This adapter attempts to convert as much of the schema as possible,
/// accumulating errors for any unsupported keywords or structures. The goal is
/// to produce a usable dartantic_ai schema even if the source schema contains
/// features not supported.
///
/// Unsupported keywords will be ignored, and a [DartanticSchemaAdapterError]
/// will be added to the [DartanticSchemaAdapterResult.errors] list for each
/// ignored keyword.
class DartanticSchemaAdapter {
  final List<DartanticSchemaAdapterError> _errors = [];

  /// Adapts the given [schema] from `json_schema_builder` to json_schema
  /// format.
  ///
  /// This is the main entry point for the adapter. It takes a [jsb.Schema] and
  /// returns a [DartanticSchemaAdapterResult] containing the adapted
  /// [JsonSchema] and a list of any errors that occurred.
  DartanticSchemaAdapterResult adapt(jsb.Schema? schema) {
    _errors.clear();
    if (schema == null) {
      return DartanticSchemaAdapterResult(null, List.unmodifiable(_errors));
    }
    final Map<String, dynamic>? schemaMap = _adaptToMap(schema, ['#']);
    final JsonSchema? dartanticSchema =
        schemaMap != null ? JsonSchema.create(schemaMap) : null;
    return DartanticSchemaAdapterResult(
      dartanticSchema,
      List.unmodifiable(_errors),
    );
  }

  /// Recursively adapts a sub-schema to a Map representation.
  ///
  /// This method is called by [adapt] and recursively traverses the schema,
  /// converting each part to a Map suitable for [JsonSchema.create].
  Map<String, dynamic>? _adaptToMap(jsb.Schema schema, List<String> path) {
    _checkUnsupportedGlobalKeywords(schema, path);

    if (schema.value.containsKey('anyOf')) {
      final Object? anyOfList = schema.value['anyOf'];
      if (anyOfList is List && anyOfList.isNotEmpty) {
        final schemas = <Map<String, dynamic>>[];
        for (var i = 0; i < anyOfList.length; i++) {
          final Object? subSchemaMap = anyOfList[i];
          if (subSchemaMap is! Map<String, Object?>) {
            _errors.add(
              DartanticSchemaAdapterError(
                'Schema inside "anyOf" must be an object.',
                path: [...path, 'anyOf', i.toString()],
              ),
            );
            continue;
          }
          final subSchema = jsb.Schema.fromMap(subSchemaMap);
          final subPath = [...path, 'anyOf', i.toString()];
          final Map<String, dynamic>? adaptedSchema =
              _adaptToMap(subSchema, subPath);
          if (adaptedSchema != null) {
            schemas.add(adaptedSchema);
          }
        }
        if (schemas.isNotEmpty) {
          return {
            'anyOf': schemas,
            if (schema.description != null) 'description': schema.description,
          };
        }
      } else {
        _errors.add(
          DartanticSchemaAdapterError(
            'The value of "anyOf" must be a non-empty array of schemas.',
            path: path,
          ),
        );
      }
    }

    final Object? type = schema.type;
    String? typeName;
    if (type is String) {
      typeName = type;
    } else if (type is List) {
      if (type.isEmpty) {
        _errors.add(
          DartanticSchemaAdapterError(
            'Schema has an empty "type" array.',
            path: path,
          ),
        );
        return null;
      }
      typeName = type.first as String;
      if (type.length > 1) {
        _errors.add(
          DartanticSchemaAdapterError(
            'Multiple types found (${type.join(', ')}). Only the first type '
            '"$typeName" will be used.',
            path: path,
          ),
        );
      }
    } else if (jsb.ObjectSchema.fromMap(schema.value).properties != null ||
        schema.value.containsKey('properties')) {
      typeName = jsb.JsonType.object.typeName;
    } else if (schema.value.containsKey('items')) {
      typeName = jsb.JsonType.list.typeName;
    }

    if (typeName == null) {
      _errors.add(
        DartanticSchemaAdapterError(
          'Schema must have a "type" or be implicitly typed with "properties" '
          'or "items".',
          path: path,
        ),
      );
      return null;
    }

    switch (typeName) {
      case 'object':
        return _adaptObject(schema, path);
      case 'array':
        return _adaptArray(schema, path);
      case 'string':
        return _adaptString(schema, path);
      case 'number':
        return _adaptNumber(schema, path);
      case 'integer':
        return _adaptInteger(schema, path);
      case 'boolean':
        return _adaptBoolean(schema, path);
      case 'null':
        return _adaptNull(schema, path);
      default:
        _errors.add(
          DartanticSchemaAdapterError(
            'Unsupported schema type "$typeName".',
            path: path,
          ),
        );
        return null;
    }
  }

  /// Checks for and logs errors for unsupported global keywords.
  void _checkUnsupportedGlobalKeywords(jsb.Schema schema, List<String> path) {
    const unsupportedKeywords = {
      '\$comment',
      'default',
      'examples',
      'deprecated',
      'readOnly',
      'writeOnly',
      '\$defs',
      '\$ref',
      '\$anchor',
      '\$dynamicAnchor',
      '\$id',
      '\$schema',
      'allOf',
      'oneOf',
      'not',
      'if',
      'then',
      'else',
      'dependentSchemas',
      'const',
    };

    for (final keyword in unsupportedKeywords) {
      if (schema.value.containsKey(keyword)) {
        _errors.add(
          DartanticSchemaAdapterError(
            'Unsupported keyword "$keyword". It will be ignored.',
            path: path,
          ),
        );
      }
    }
  }

  /// Adapts an object schema.
  Map<String, dynamic>? _adaptObject(jsb.Schema dsbSchema, List<String> path) {
    final objectSchema = jsb.ObjectSchema.fromMap(dsbSchema.value);
    final properties = <String, Map<String, dynamic>>{};
    if (objectSchema.properties != null) {
      for (final MapEntry<String, jsb.Schema> entry
          in objectSchema.properties!.entries) {
        final List<String> propertyPath = [...path, 'properties', entry.key];
        final Map<String, dynamic>? adaptedProperty =
            _adaptToMap(entry.value, propertyPath);
        if (adaptedProperty != null) {
          properties[entry.key] = adaptedProperty;
        }
      }
    }

    _warnIfPresent(objectSchema.patternProperties, 'patternProperties', path);
    _warnIfPresent(objectSchema.dependentRequired, 'dependentRequired', path);
    _warnIfPresent(
      objectSchema.additionalProperties,
      'additionalProperties',
      path,
    );
    _warnIfPresent(
      objectSchema.unevaluatedProperties,
      'unevaluatedProperties',
      path,
    );
    _warnIfPresent(objectSchema.propertyNames, 'propertyNames', path);
    _warnIfPresent(objectSchema.minProperties, 'minProperties', path);
    _warnIfPresent(objectSchema.maxProperties, 'maxProperties', path);

    return {
      'type': 'object',
      if (properties.isNotEmpty) 'properties': properties,
      if (objectSchema.required != null && objectSchema.required!.isNotEmpty)
        'required': objectSchema.required,
      if (dsbSchema.description != null) 'description': dsbSchema.description,
    };
  }

  /// Adapts an array schema.
  Map<String, dynamic>? _adaptArray(jsb.Schema dsbSchema, List<String> path) {
    final listSchema = jsb.ListSchema.fromMap(dsbSchema.value);

    if (listSchema.items == null) {
      _errors.add(
        DartanticSchemaAdapterError(
          'Array schema must have an "items" property.',
          path: path,
        ),
      );
      return null;
    }

    final itemsPath = [...path, 'items'];
    final Map<String, dynamic>? adaptedItems =
        _adaptToMap(listSchema.items!, itemsPath);
    if (adaptedItems == null) {
      return null;
    }

    _warnIfPresent(listSchema.prefixItems, 'prefixItems', path);
    _warnIfPresent(listSchema.unevaluatedItems, 'unevaluatedItems', path);
    _warnIfPresent(listSchema.contains, 'contains', path);
    _warnIfPresent(listSchema.minContains, 'minContains', path);
    _warnIfPresent(listSchema.maxContains, 'maxContains', path);
    if (listSchema.uniqueItems ?? false) {
      _warnIfPresent(true, 'uniqueItems', path);
    }

    return {
      'type': 'array',
      'items': adaptedItems,
      if (listSchema.minItems != null) 'minItems': listSchema.minItems,
      if (listSchema.maxItems != null) 'maxItems': listSchema.maxItems,
      if (dsbSchema.description != null) 'description': dsbSchema.description,
    };
  }

  /// Adapts a string schema.
  Map<String, dynamic>? _adaptString(jsb.Schema dsbSchema, List<String> path) {
    final stringSchema = jsb.StringSchema.fromMap(dsbSchema.value);
    _warnIfPresent(stringSchema.minLength, 'minLength', path);
    _warnIfPresent(stringSchema.maxLength, 'maxLength', path);
    _warnIfPresent(stringSchema.pattern, 'pattern', path);

    return {
      'type': 'string',
      if (stringSchema.format != null) 'format': stringSchema.format,
      if (stringSchema.enumValues != null &&
          stringSchema.enumValues!.isNotEmpty)
        'enum': stringSchema.enumValues,
      if (dsbSchema.description != null) 'description': dsbSchema.description,
    };
  }

  /// Adapts a number schema.
  Map<String, dynamic>? _adaptNumber(jsb.Schema dsbSchema, List<String> path) {
    final numberSchema = jsb.NumberSchema.fromMap(dsbSchema.value);
    _warnIfPresent(numberSchema.exclusiveMinimum, 'exclusiveMinimum', path);
    _warnIfPresent(numberSchema.exclusiveMaximum, 'exclusiveMaximum', path);
    _warnIfPresent(numberSchema.multipleOf, 'multipleOf', path);

    return {
      'type': 'number',
      if (numberSchema.minimum != null) 'minimum': numberSchema.minimum,
      if (numberSchema.maximum != null) 'maximum': numberSchema.maximum,
      if (dsbSchema.description != null) 'description': dsbSchema.description,
    };
  }

  /// Adapts an integer schema.
  Map<String, dynamic>? _adaptInteger(jsb.Schema dsbSchema, List<String> path) {
    final integerSchema = jsb.IntegerSchema.fromMap(dsbSchema.value);
    _warnIfPresent(integerSchema.exclusiveMinimum, 'exclusiveMinimum', path);
    _warnIfPresent(integerSchema.exclusiveMaximum, 'exclusiveMaximum', path);
    _warnIfPresent(integerSchema.multipleOf, 'multipleOf', path);

    return {
      'type': 'integer',
      if (integerSchema.minimum != null) 'minimum': integerSchema.minimum,
      if (integerSchema.maximum != null) 'maximum': integerSchema.maximum,
      if (dsbSchema.description != null) 'description': dsbSchema.description,
    };
  }

  /// Adapts a boolean schema.
  Map<String, dynamic>? _adaptBoolean(jsb.Schema dsbSchema, List<String> path) {
    return {
      'type': 'boolean',
      if (dsbSchema.description != null) 'description': dsbSchema.description,
    };
  }

  /// Adapts a null schema.
  Map<String, dynamic>? _adaptNull(jsb.Schema dsbSchema, List<String> path) {
    return {
      'type': 'null',
      if (dsbSchema.description != null) 'description': dsbSchema.description,
    };
  }

  /// Helper to warn about unsupported keywords.
  void _warnIfPresent(Object? value, String keyword, List<String> path) {
    if (value != null) {
      _errors.add(
        DartanticSchemaAdapterError(
          'Unsupported keyword "$keyword". It will be ignored.',
          path: path,
        ),
      );
    }
  }
}
