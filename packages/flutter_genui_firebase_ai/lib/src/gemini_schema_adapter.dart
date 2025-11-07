// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_ai/firebase_ai.dart' as firebase_ai;
import 'package:json_schema_builder/json_schema_builder.dart' as dsb;

/// An error that occurred during schema adaptation.
///
/// This class encapsulates information about an error that occurred while
/// converting a `json_schema_builder` schema to a `firebase_ai` schema.
class GeminiSchemaAdapterError {
  /// Creates an [GeminiSchemaAdapterError].
  ///
  /// The [message] describes the error, and the [path] indicates where in the
  /// schema the error occurred.
  GeminiSchemaAdapterError(this.message, {required this.path});

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
class GeminiSchemaAdapterResult {
  /// Creates an [GeminiSchemaAdapterResult].
  ///
  /// The [schema] is the result of the adaptation, and [errors] is a list of
  /// any errors that were encountered.
  GeminiSchemaAdapterResult(this.schema, this.errors);

  /// The adapted schema.
  ///
  /// This may be null if the schema could not be adapted at all.
  final firebase_ai.Schema? schema;

  /// A list of errors that occurred during adaptation.
  final List<GeminiSchemaAdapterError> errors;
}

/// An adapter to convert a [dsb.Schema] from the `json_schema_builder` package
/// to a [firebase_ai.Schema] from the `firebase_ai` package.
///
/// This adapter attempts to convert as much of the schema as possible,
/// accumulating errors for any unsupported keywords or structures. The goal is
/// to produce a usable `firebase_ai` schema even if the source schema contains
/// features not supported by `firebase_ai`.
///
/// Unsupported keywords will be ignored, and an [GeminiSchemaAdapterError] will
/// be added to the [GeminiSchemaAdapterResult.errors] list for each ignored
/// keyword.
class GeminiSchemaAdapter {
  final List<GeminiSchemaAdapterError> _errors = [];

  /// Adapts the given [schema] from `json_schema_builder` to `firebase_ai`
  /// format.
  ///
  /// This is the main entry point for the adapter. It takes a [dsb.Schema] and
  /// returns an [GeminiSchemaAdapterResult] containing the adapted
  /// [firebase_ai.Schema] and a list of any errors that occurred.
  GeminiSchemaAdapterResult adapt(dsb.Schema schema) {
    _errors.clear();
    final firebase_ai.Schema? firebaseSchema = _adapt(schema, ['#']);
    return GeminiSchemaAdapterResult(
      firebaseSchema,
      List.unmodifiable(_errors),
    );
  }

  /// Recursively adapts a sub-schema.
  ///
  /// This method is called by [adapt] and recursively traverses the schema,
  /// converting each part to the `firebase_ai` format.
  firebase_ai.Schema? _adapt(dsb.Schema schema, List<String> path) {
    checkUnsupportedGlobalKeywords(schema, path);

    if (schema.value.containsKey('anyOf')) {
      final Object? anyOfList = schema.value['anyOf'];
      if (anyOfList is List && anyOfList.isNotEmpty) {
        final schemas = <firebase_ai.Schema>[];
        for (var i = 0; i < anyOfList.length; i++) {
          final Object? subSchemaMap = anyOfList[i];
          if (subSchemaMap is! Map<String, Object?>) {
            _errors.add(
              GeminiSchemaAdapterError(
                'Schema inside "anyOf" must be an object.',
                path: [...path, 'anyOf', i.toString()],
              ),
            );
            continue;
          }
          final subSchema = dsb.Schema.fromMap(subSchemaMap);
          final subPath = [...path, 'anyOf', i.toString()];
          final firebase_ai.Schema? adaptedSchema = _adapt(subSchema, subPath);
          if (adaptedSchema != null) {
            schemas.add(adaptedSchema);
          }
        }
        if (schemas.isNotEmpty) {
          return firebase_ai.Schema.anyOf(schemas: schemas);
        }
      } else {
        _errors.add(
          GeminiSchemaAdapterError(
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
          GeminiSchemaAdapterError(
            'Schema has an empty "type" array.',
            path: path,
          ),
        );
        return null;
      }
      typeName = type.first as String;
      if (type.length > 1) {
        _errors.add(
          GeminiSchemaAdapterError(
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
        GeminiSchemaAdapterError(
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
          GeminiSchemaAdapterError(
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
          GeminiSchemaAdapterError(
            'Unsupported keyword "$keyword". It will be ignored.',
            path: path,
          ),
        );
      }
    }
  }

  /// Adapts an object schema.
  firebase_ai.Schema? _adaptObject(dsb.Schema dsbSchema, List<String> path) {
    final objectSchema = dsb.ObjectSchema.fromMap(dsbSchema.value);
    final properties = <String, firebase_ai.Schema>{};
    if (objectSchema.properties != null) {
      for (final MapEntry<String, dsb.Schema> entry
          in objectSchema.properties!.entries) {
        final List<String> propertyPath = [...path, 'properties', entry.key];
        final firebase_ai.Schema? adaptedProperty = _adapt(
          entry.value,
          propertyPath,
        );
        if (adaptedProperty != null) {
          properties[entry.key] = adaptedProperty;
        }
      }
    }

    if (objectSchema.patternProperties != null) {
      _errors.add(
        GeminiSchemaAdapterError(
          'Unsupported keyword "patternProperties". It will be ignored.',
          path: path,
        ),
      );
    }
    if (objectSchema.dependentRequired != null) {
      _errors.add(
        GeminiSchemaAdapterError(
          'Unsupported keyword "dependentRequired". It will be ignored.',
          path: path,
        ),
      );
    }
    if (objectSchema.additionalProperties != null) {
      _errors.add(
        GeminiSchemaAdapterError(
          'Unsupported keyword "additionalProperties". It will be ignored.',
          path: path,
        ),
      );
    }
    if (objectSchema.unevaluatedProperties != null) {
      _errors.add(
        GeminiSchemaAdapterError(
          'Unsupported keyword "unevaluatedProperties". It will be ignored.',
          path: path,
        ),
      );
    }
    if (objectSchema.propertyNames != null) {
      _errors.add(
        GeminiSchemaAdapterError(
          'Unsupported keyword "propertyNames". It will be ignored.',
          path: path,
        ),
      );
    }
    if (objectSchema.minProperties != null) {
      _errors.add(
        GeminiSchemaAdapterError(
          'Unsupported keyword "minProperties". It will be ignored.',
          path: path,
        ),
      );
    }
    if (objectSchema.maxProperties != null) {
      _errors.add(
        GeminiSchemaAdapterError(
          'Unsupported keyword "maxProperties". It will be ignored.',
          path: path,
        ),
      );
    }

    final Set<String> allProperties = properties.keys.toSet();
    final Set<String> requiredProperties = objectSchema.required?.toSet() ?? {};
    final List<String> optionalProperties = allProperties
        .difference(requiredProperties)
        .toList();

    return firebase_ai.Schema(
      firebase_ai.SchemaType.object,
      properties: properties,
      optionalProperties: optionalProperties,
      description: dsbSchema.description,
    );
  }

  /// Adapts an array schema.
  firebase_ai.Schema? _adaptArray(dsb.Schema dsbSchema, List<String> path) {
    final listSchema = dsb.ListSchema.fromMap(dsbSchema.value);

    if (listSchema.items == null) {
      _errors.add(
        GeminiSchemaAdapterError(
          'Array schema must have an "items" property.',
          path: path,
        ),
      );
      return null;
    }

    final itemsPath = [...path, 'items'];
    final firebase_ai.Schema? adaptedItems = _adapt(
      listSchema.items!,
      itemsPath,
    );
    if (adaptedItems == null) {
      return null;
    }

    if (listSchema.prefixItems != null) {
      _errors.add(
        GeminiSchemaAdapterError(
          'Unsupported keyword "prefixItems". It will be ignored.',
          path: path,
        ),
      );
    }
    if (listSchema.unevaluatedItems != null) {
      _errors.add(
        GeminiSchemaAdapterError(
          'Unsupported keyword "unevaluatedItems". It will be ignored.',
          path: path,
        ),
      );
    }
    if (listSchema.contains != null) {
      _errors.add(
        GeminiSchemaAdapterError(
          'Unsupported keyword "contains". It will be ignored.',
          path: path,
        ),
      );
    }
    if (listSchema.minContains != null) {
      _errors.add(
        GeminiSchemaAdapterError(
          'Unsupported keyword "minContains". It will be ignored.',
          path: path,
        ),
      );
    }
    if (listSchema.maxContains != null) {
      _errors.add(
        GeminiSchemaAdapterError(
          'Unsupported keyword "maxContains". It will be ignored.',
          path: path,
        ),
      );
    }
    if (listSchema.uniqueItems ?? false) {
      _errors.add(
        GeminiSchemaAdapterError(
          'Unsupported keyword "uniqueItems". It will be ignored.',
          path: path,
        ),
      );
    }

    return firebase_ai.Schema(
      firebase_ai.SchemaType.array,
      items: adaptedItems,
      minItems: listSchema.minItems,
      maxItems: listSchema.maxItems,
      description: dsbSchema.description,
    );
  }

  /// Adapts a string schema.
  firebase_ai.Schema? _adaptString(dsb.Schema dsbSchema, List<String> path) {
    final stringSchema = dsb.StringSchema.fromMap(dsbSchema.value);
    if (stringSchema.minLength != null) {
      _errors.add(
        GeminiSchemaAdapterError(
          'Unsupported keyword "minLength". It will be ignored.',
          path: path,
        ),
      );
    }
    if (stringSchema.maxLength != null) {
      _errors.add(
        GeminiSchemaAdapterError(
          'Unsupported keyword "maxLength". It will be ignored.',
          path: path,
        ),
      );
    }
    if (stringSchema.pattern != null) {
      _errors.add(
        GeminiSchemaAdapterError(
          'Unsupported keyword "pattern". It will be ignored.',
          path: path,
        ),
      );
    }
    return firebase_ai.Schema(
      firebase_ai.SchemaType.string,
      format: stringSchema.format,
      enumValues: stringSchema.enumValues?.map((e) => e.toString()).toList(),
      description: dsbSchema.description,
    );
  }

  /// Adapts a number schema.
  firebase_ai.Schema? _adaptNumber(dsb.Schema dsbSchema, List<String> path) {
    final numberSchema = dsb.NumberSchema.fromMap(dsbSchema.value);
    if (numberSchema.exclusiveMinimum != null) {
      _errors.add(
        GeminiSchemaAdapterError(
          'Unsupported keyword "exclusiveMinimum". It will be ignored.',
          path: path,
        ),
      );
    }
    if (numberSchema.exclusiveMaximum != null) {
      _errors.add(
        GeminiSchemaAdapterError(
          'Unsupported keyword "exclusiveMaximum". It will be ignored.',
          path: path,
        ),
      );
    }
    if (numberSchema.multipleOf != null) {
      _errors.add(
        GeminiSchemaAdapterError(
          'Unsupported keyword "multipleOf". It will be ignored.',
          path: path,
        ),
      );
    }
    return firebase_ai.Schema(
      firebase_ai.SchemaType.number,
      minimum: numberSchema.minimum?.toDouble(),
      maximum: numberSchema.maximum?.toDouble(),
      description: dsbSchema.description,
    );
  }

  /// Adapts an integer schema.
  firebase_ai.Schema? _adaptInteger(dsb.Schema dsbSchema, List<String> path) {
    final integerSchema = dsb.IntegerSchema.fromMap(dsbSchema.value);
    if (integerSchema.exclusiveMinimum != null) {
      _errors.add(
        GeminiSchemaAdapterError(
          'Unsupported keyword "exclusiveMinimum". It will be ignored.',
          path: path,
        ),
      );
    }
    if (integerSchema.exclusiveMaximum != null) {
      _errors.add(
        GeminiSchemaAdapterError(
          'Unsupported keyword "exclusiveMaximum". It will be ignored.',
          path: path,
        ),
      );
    }
    if (integerSchema.multipleOf != null) {
      _errors.add(
        GeminiSchemaAdapterError(
          'Unsupported keyword "multipleOf". It will be ignored.',
          path: path,
        ),
      );
    }
    return firebase_ai.Schema(
      firebase_ai.SchemaType.integer,
      minimum: integerSchema.minimum?.toDouble(),
      maximum: integerSchema.maximum?.toDouble(),
      description: dsbSchema.description,
    );
  }

  /// Adapts a boolean schema.
  firebase_ai.Schema? _adaptBoolean(dsb.Schema dsbSchema, List<String> path) {
    return firebase_ai.Schema(
      firebase_ai.SchemaType.boolean,
      description: dsbSchema.description,
    );
  }

  /// Adapts a null schema.
  firebase_ai.Schema? _adaptNull(dsb.Schema dsbSchema, List<String> path) {
    return firebase_ai.Schema(
      firebase_ai.SchemaType.object,
      nullable: true,
      description: dsbSchema.description,
    );
  }
}
