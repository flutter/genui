// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_schema_builder/json_schema_builder.dart' as dsb;
import 'package:json_schema/json_schema.dart' as js;

/// An error that occurred during schema adaptation.
///
/// This class encapsulates information about an error that occurred while
/// converting a `json_schema_builder` schema to a `json_schema` schema.
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
  final js.JsonSchema? schema;

  /// A list of errors that occurred during adaptation.
  final List<DartanticSchemaAdapterError> errors;
}

/// An adapter to convert a [dsb.Schema] from the `json_schema_builder` package
/// to a [js.JsonSchema] from the `json_schema` package.
///
/// This adapter attempts to convert as much of the schema as possible,
/// accumulating errors for any unsupported keywords or structures. The goal is
/// to produce a usable `json_schema` schema even if the source schema contains
/// features not supported by the `json_schema` package.
///
/// Unsupported keywords will be ignored, and a [DartanticSchemaAdapterError] will
/// be added to the [DartanticSchemaAdapterResult.errors] list for each ignored
/// keyword.
class DartanticSchemaAdapter {
  final List<DartanticSchemaAdapterError> _errors = [];

  /// Adapts the given [schema] from `json_schema_builder` to `json_schema`
  /// format.
  ///
  /// This is the main entry point for the adapter. It takes a [dsb.Schema] and
  /// returns a [DartanticSchemaAdapterResult] containing the adapted
  /// [js.JsonSchema] and a list of any errors that occurred.
  DartanticSchemaAdapterResult adapt(dsb.Schema schema) {
    _errors.clear();
    final jsonSchema = _adapt(schema, ['#']);
    return DartanticSchemaAdapterResult(
      jsonSchema,
      List.unmodifiable(_errors),
    );
  }

  /// Recursively adapts a sub-schema.
  ///
  /// This method is called by [adapt] and recursively traverses the schema,
  /// converting each part to the `json_schema` format.
  js.JsonSchema? _adapt(dsb.Schema schema, List<String> path) {
    checkUnsupportedGlobalKeywords(schema, path);

    if (schema.value.containsKey('anyOf')) {
      final anyOfList = schema.value['anyOf'];
      if (anyOfList is List && anyOfList.isNotEmpty) {
        final schemas = <js.JsonSchema>[];
        for (var i = 0; i < anyOfList.length; i++) {
          final subSchemaMap = anyOfList[i];
          if (subSchemaMap is! Map<String, dynamic>) {
            _errors.add(
              DartanticSchemaAdapterError(
                'Schema inside "anyOf" must be an object.',
                path: [...path, 'anyOf', i.toString()],
              ),
            );
            continue;
          }
          final subSchema = dsb.Schema.fromMap(subSchemaMap);
          final subPath = [...path, 'anyOf', i.toString()];
          final adaptedSchema = _adapt(subSchema, subPath);
          if (adaptedSchema != null) {
            schemas.add(adaptedSchema);
          }
        }
        if (schemas.isNotEmpty) {
          return js.JsonSchema.create({
            'anyOf': schemas.map((s) => s.schemaMap).toList(),
          });
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

    final type = schema.type;
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
    } else if (dsb.ObjectSchema.fromMap(schema.value).properties != null ||
        schema.value.containsKey('properties')) {
      typeName = dsb.JsonType.object.typeName;
    } else if (schema.value.containsKey('items')) {
      typeName = dsb.JsonType.list.typeName;
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
  void checkUnsupportedGlobalKeywords(dsb.Schema schema, List<String> path) {
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
  js.JsonSchema? _adaptObject(dsb.Schema dsbSchema, List<String> path) {
    final objectSchema = dsb.ObjectSchema.fromMap(dsbSchema.value);
    final properties = <String, dynamic>{};
    if (objectSchema.properties != null) {
      for (final entry in objectSchema.properties!.entries) {
        final propertyPath = [...path, 'properties', entry.key];
        final adaptedProperty = _adapt(entry.value, propertyPath);
        if (adaptedProperty != null) {
          properties[entry.key] = adaptedProperty.schemaMap;
        }
      }
    }

    if (objectSchema.patternProperties != null) {
      _errors.add(
        DartanticSchemaAdapterError(
          'Unsupported keyword "patternProperties". It will be ignored.',
          path: path,
        ),
      );
    }
    if (objectSchema.dependentRequired != null) {
      _errors.add(
        DartanticSchemaAdapterError(
          'Unsupported keyword "dependentRequired". It will be ignored.',
          path: path,
        ),
      );
    }
    if (objectSchema.additionalProperties != null) {
      _errors.add(
        DartanticSchemaAdapterError(
          'Unsupported keyword "additionalProperties". It will be ignored.',
          path: path,
        ),
      );
    }
    if (objectSchema.unevaluatedProperties != null) {
      _errors.add(
        DartanticSchemaAdapterError(
          'Unsupported keyword "unevaluatedProperties". It will be ignored.',
          path: path,
        ),
      );
    }
    if (objectSchema.propertyNames != null) {
      _errors.add(
        DartanticSchemaAdapterError(
          'Unsupported keyword "propertyNames". It will be ignored.',
          path: path,
        ),
      );
    }
    if (objectSchema.minProperties != null) {
      _errors.add(
        DartanticSchemaAdapterError(
          'Unsupported keyword "minProperties". It will be ignored.',
          path: path,
        ),
      );
    }
    if (objectSchema.maxProperties != null) {
      _errors.add(
        DartanticSchemaAdapterError(
          'Unsupported keyword "maxProperties". It will be ignored.',
          path: path,
        ),
      );
    }

    final schemaMap = <String, dynamic>{
      'type': 'object',
      'properties': properties,
    };

    if (objectSchema.required != null && objectSchema.required!.isNotEmpty) {
      schemaMap['required'] = objectSchema.required!.toList();
    }

    if (dsbSchema.description != null) {
      schemaMap['description'] = dsbSchema.description;
    }

    return js.JsonSchema.create(schemaMap);
  }

  /// Adapts an array schema.
  js.JsonSchema? _adaptArray(dsb.Schema dsbSchema, List<String> path) {
    final listSchema = dsb.ListSchema.fromMap(dsbSchema.value);

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
    final adaptedItems = _adapt(listSchema.items!, itemsPath);
    if (adaptedItems == null) {
      return null;
    }

    if (listSchema.prefixItems != null) {
      _errors.add(
        DartanticSchemaAdapterError(
          'Unsupported keyword "prefixItems". It will be ignored.',
          path: path,
        ),
      );
    }
    if (listSchema.unevaluatedItems != null) {
      _errors.add(
        DartanticSchemaAdapterError(
          'Unsupported keyword "unevaluatedItems". It will be ignored.',
          path: path,
        ),
      );
    }
    if (listSchema.contains != null) {
      _errors.add(
        DartanticSchemaAdapterError(
          'Unsupported keyword "contains". It will be ignored.',
          path: path,
        ),
      );
    }
    if (listSchema.minContains != null) {
      _errors.add(
        DartanticSchemaAdapterError(
          'Unsupported keyword "minContains". It will be ignored.',
          path: path,
        ),
      );
    }
    if (listSchema.maxContains != null) {
      _errors.add(
        DartanticSchemaAdapterError(
          'Unsupported keyword "maxContains". It will be ignored.',
          path: path,
        ),
      );
    }
    if (listSchema.uniqueItems ?? false) {
      _errors.add(
        DartanticSchemaAdapterError(
          'Unsupported keyword "uniqueItems". It will be ignored.',
          path: path,
        ),
      );
    }

    final schemaMap = <String, dynamic>{
      'type': 'array',
      'items': adaptedItems.schemaMap,
    };

    if (listSchema.minItems != null) {
      schemaMap['minItems'] = listSchema.minItems;
    }
    if (listSchema.maxItems != null) {
      schemaMap['maxItems'] = listSchema.maxItems;
    }
    if (dsbSchema.description != null) {
      schemaMap['description'] = dsbSchema.description;
    }

    return js.JsonSchema.create(schemaMap);
  }

  /// Adapts a string schema.
  js.JsonSchema? _adaptString(dsb.Schema dsbSchema, List<String> path) {
    final stringSchema = dsb.StringSchema.fromMap(dsbSchema.value);
    
    final schemaMap = <String, dynamic>{
      'type': 'string',
    };

    if (stringSchema.minLength != null) {
      schemaMap['minLength'] = stringSchema.minLength;
    }
    if (stringSchema.maxLength != null) {
      schemaMap['maxLength'] = stringSchema.maxLength;
    }
    if (stringSchema.pattern != null) {
      schemaMap['pattern'] = stringSchema.pattern;
    }
    if (stringSchema.format != null) {
      schemaMap['format'] = stringSchema.format;
    }
    if (stringSchema.enumValues != null && stringSchema.enumValues!.isNotEmpty) {
      schemaMap['enum'] = stringSchema.enumValues!.map((e) => e.toString()).toList();
    }
    if (dsbSchema.description != null) {
      schemaMap['description'] = dsbSchema.description;
    }

    return js.JsonSchema.create(schemaMap);
  }

  /// Adapts a number schema.
  js.JsonSchema? _adaptNumber(dsb.Schema dsbSchema, List<String> path) {
    final numberSchema = dsb.NumberSchema.fromMap(dsbSchema.value);
    
    final schemaMap = <String, dynamic>{
      'type': 'number',
    };

    if (numberSchema.minimum != null) {
      schemaMap['minimum'] = numberSchema.minimum;
    }
    if (numberSchema.maximum != null) {
      schemaMap['maximum'] = numberSchema.maximum;
    }
    if (numberSchema.exclusiveMinimum != null) {
      schemaMap['exclusiveMinimum'] = numberSchema.exclusiveMinimum;
    }
    if (numberSchema.exclusiveMaximum != null) {
      schemaMap['exclusiveMaximum'] = numberSchema.exclusiveMaximum;
    }
    if (numberSchema.multipleOf != null) {
      schemaMap['multipleOf'] = numberSchema.multipleOf;
    }
    if (dsbSchema.description != null) {
      schemaMap['description'] = dsbSchema.description;
    }

    return js.JsonSchema.create(schemaMap);
  }

  /// Adapts an integer schema.
  js.JsonSchema? _adaptInteger(dsb.Schema dsbSchema, List<String> path) {
    final integerSchema = dsb.IntegerSchema.fromMap(dsbSchema.value);
    
    final schemaMap = <String, dynamic>{
      'type': 'integer',
    };

    if (integerSchema.minimum != null) {
      schemaMap['minimum'] = integerSchema.minimum;
    }
    if (integerSchema.maximum != null) {
      schemaMap['maximum'] = integerSchema.maximum;
    }
    if (integerSchema.exclusiveMinimum != null) {
      schemaMap['exclusiveMinimum'] = integerSchema.exclusiveMinimum;
    }
    if (integerSchema.exclusiveMaximum != null) {
      schemaMap['exclusiveMaximum'] = integerSchema.exclusiveMaximum;
    }
    if (integerSchema.multipleOf != null) {
      schemaMap['multipleOf'] = integerSchema.multipleOf;
    }
    if (dsbSchema.description != null) {
      schemaMap['description'] = dsbSchema.description;
    }

    return js.JsonSchema.create(schemaMap);
  }

  /// Adapts a boolean schema.
  js.JsonSchema? _adaptBoolean(dsb.Schema dsbSchema, List<String> path) {
    final schemaMap = <String, dynamic>{
      'type': 'boolean',
    };

    if (dsbSchema.description != null) {
      schemaMap['description'] = dsbSchema.description;
    }

    return js.JsonSchema.create(schemaMap);
  }

  /// Adapts a null schema.
  js.JsonSchema? _adaptNull(dsb.Schema dsbSchema, List<String> path) {
    final schemaMap = <String, dynamic>{
      'type': 'null',
    };

    if (dsbSchema.description != null) {
      schemaMap['description'] = dsbSchema.description;
    }

    return js.JsonSchema.create(schemaMap);
  }
}
