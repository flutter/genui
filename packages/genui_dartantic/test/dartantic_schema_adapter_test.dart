// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid_dynamic_calls

import 'package:flutter_test/flutter_test.dart';
import 'package:genui_dartantic/genui_dartantic.dart';
import 'package:json_schema_builder/json_schema_builder.dart' as dsb;

void main() {
  group('DartanticSchemaAdapter', () {
    late DartanticSchemaAdapter adapter;

    setUp(() {
      adapter = DartanticSchemaAdapter();
    });

    group('adaptObject', () {
      test('should adapt a simple object schema', () {
        final dsbSchema = dsb.Schema.object(
          properties: {
            'name': dsb.Schema.string(description: 'The name of the person.'),
            'age': dsb.Schema.integer(description: 'The age of the person.'),
          },
          required: ['name'],
          description: 'A person object.',
        );

        final DartanticSchemaAdapterResult result = adapter.adapt(dsbSchema);

        expect(result.errors, isEmpty);
        expect(result.schema, isNotNull);
        // Verify the schema map structure
        final Map<dynamic, dynamic> schemaMap = result.schema!.schemaMap!;
        expect(schemaMap['type'], 'object');
        expect(schemaMap['description'], 'A person object.');
        expect(schemaMap['properties'], isA<Map>());
        expect(schemaMap['required'], ['name']);
      });

      test('should handle unsupported keywords and log errors', () {
        final dsbSchema = dsb.Schema.object(
          properties: {'name': dsb.Schema.string()},
          minProperties: 1,
          maxProperties: 5,
          additionalProperties: dsb.Schema.boolean(),
        );

        final DartanticSchemaAdapterResult result = adapter.adapt(dsbSchema);

        expect(result.errors, hasLength(3));
        expect(
          result.errors[0].message,
          contains('Unsupported keyword "additionalProperties"'),
        );
        expect(
          result.errors[1].message,
          contains('Unsupported keyword "minProperties"'),
        );
        expect(
          result.errors[2].message,
          contains('Unsupported keyword "maxProperties"'),
        );
        expect(result.schema, isNotNull);
      });
    });

    group('adaptArray', () {
      test('should adapt a simple array schema', () {
        final dsbSchema = dsb.Schema.list(
          items: dsb.Schema.string(),
          minItems: 1,
          maxItems: 10,
          description: 'A list of items.',
        );

        final DartanticSchemaAdapterResult result = adapter.adapt(dsbSchema);

        expect(result.errors, isEmpty);
        expect(result.schema, isNotNull);
        final Map<dynamic, dynamic> schemaMap = result.schema!.schemaMap!;
        expect(schemaMap['type'], 'array');
        expect(schemaMap['description'], 'A list of items.');
        expect(schemaMap['minItems'], 1);
        expect(schemaMap['maxItems'], 10);
      });

      test('should log an error if items is missing', () {
        final dsbSchema = dsb.Schema.fromMap({'type': 'array'});
        final DartanticSchemaAdapterResult result = adapter.adapt(dsbSchema);
        expect(result.errors, isNotEmpty);
        expect(
          result.errors.first.message,
          'Array schema must have an "items" property.',
        );
        expect(result.schema, isNull);
      });

      test('should handle unsupported keywords and log errors', () {
        final dsbSchema = dsb.Schema.list(
          items: dsb.Schema.string(),
          uniqueItems: true,
        );

        final DartanticSchemaAdapterResult result = adapter.adapt(dsbSchema);

        expect(result.errors, hasLength(1));
        expect(
          result.errors[0].message,
          contains('Unsupported keyword "uniqueItems"'),
        );
        expect(result.schema, isNotNull);
      });
    });

    group('adaptString', () {
      test('should adapt a simple string schema', () {
        final dsbSchema = dsb.Schema.string(
          format: 'email',
          enumValues: ['test@example.com', 'user@example.com'],
          description: 'An email address.',
        );

        final DartanticSchemaAdapterResult result = adapter.adapt(dsbSchema);

        expect(result.errors, isEmpty);
        expect(result.schema, isNotNull);
        final Map<dynamic, dynamic> schemaMap = result.schema!.schemaMap!;
        expect(schemaMap['type'], 'string');
        expect(schemaMap['description'], 'An email address.');
        expect(schemaMap['format'], 'email');
        expect(schemaMap['enum'], ['test@example.com', 'user@example.com']);
      });

      test('should handle unsupported keywords and log errors', () {
        final dsbSchema = dsb.Schema.string(
          minLength: 1,
          maxLength: 10,
          pattern: r'^[a-zA-Z]+$',
        );

        final DartanticSchemaAdapterResult result = adapter.adapt(dsbSchema);

        expect(result.errors, hasLength(3));
        expect(
          result.errors[0].message,
          contains('Unsupported keyword "minLength"'),
        );
        expect(
          result.errors[1].message,
          contains('Unsupported keyword "maxLength"'),
        );
        expect(
          result.errors[2].message,
          contains('Unsupported keyword "pattern"'),
        );
        expect(result.schema, isNotNull);
      });
    });

    group('adaptNumber', () {
      test('should adapt a simple number schema', () {
        final dsbSchema = dsb.Schema.number(minimum: 0.0, maximum: 100.0);

        final DartanticSchemaAdapterResult result = adapter.adapt(dsbSchema);

        expect(result.errors, isEmpty);
        expect(result.schema, isNotNull);
        final Map<dynamic, dynamic> schemaMap = result.schema!.schemaMap!;
        expect(schemaMap['type'], 'number');
        expect(schemaMap['minimum'], 0.0);
        expect(schemaMap['maximum'], 100.0);
      });

      test('should handle unsupported keywords and log errors', () {
        final dsbSchema = dsb.Schema.number(
          exclusiveMinimum: 0.0,
          exclusiveMaximum: 100.0,
          multipleOf: 5.0,
        );

        final DartanticSchemaAdapterResult result = adapter.adapt(dsbSchema);

        expect(result.errors, hasLength(3));
        expect(
          result.errors[0].message,
          contains('Unsupported keyword "exclusiveMinimum"'),
        );
        expect(
          result.errors[1].message,
          contains('Unsupported keyword "exclusiveMaximum"'),
        );
        expect(
          result.errors[2].message,
          contains('Unsupported keyword "multipleOf"'),
        );
        expect(result.schema, isNotNull);
      });
    });

    group('adaptInteger', () {
      test('should adapt a simple integer schema', () {
        final dsbSchema = dsb.Schema.integer(minimum: 0, maximum: 100);

        final DartanticSchemaAdapterResult result = adapter.adapt(dsbSchema);

        expect(result.errors, isEmpty);
        expect(result.schema, isNotNull);
        final Map<dynamic, dynamic> schemaMap = result.schema!.schemaMap!;
        expect(schemaMap['type'], 'integer');
        expect(schemaMap['minimum'], 0);
        expect(schemaMap['maximum'], 100);
      });

      test('should handle unsupported keywords and log errors', () {
        final dsbSchema = dsb.Schema.integer(
          exclusiveMinimum: 0,
          exclusiveMaximum: 100,
          multipleOf: 5,
        );

        final DartanticSchemaAdapterResult result = adapter.adapt(dsbSchema);

        expect(result.errors, hasLength(3));
        expect(
          result.errors[0].message,
          contains('Unsupported keyword "exclusiveMinimum"'),
        );
        expect(
          result.errors[1].message,
          contains('Unsupported keyword "exclusiveMaximum"'),
        );
        expect(
          result.errors[2].message,
          contains('Unsupported keyword "multipleOf"'),
        );
        expect(result.schema, isNotNull);
      });
    });

    group('adaptBoolean', () {
      test('should adapt a boolean schema', () {
        final dsbSchema = dsb.Schema.boolean();
        final DartanticSchemaAdapterResult result = adapter.adapt(dsbSchema);
        expect(result.errors, isEmpty);
        expect(result.schema, isNotNull);
        expect(result.schema!.schemaMap!['type'], 'boolean');
      });
    });

    group('adaptNull', () {
      test('should adapt a null schema', () {
        final dsbSchema = dsb.Schema.nil();
        final DartanticSchemaAdapterResult result = adapter.adapt(dsbSchema);
        expect(result.schema, isNotNull);
        expect(result.schema!.schemaMap!['type'], 'null');
      });
    });

    group('General Error Handling', () {
      test('should return null schema for null input', () {
        final DartanticSchemaAdapterResult result = adapter.adapt(null);
        expect(result.schema, isNull);
        expect(result.errors, isEmpty);
      });

      test('should log an error for an unknown type', () {
        final dsbSchema = dsb.Schema.fromMap({'type': 'unknown'});
        final DartanticSchemaAdapterResult result = adapter.adapt(dsbSchema);
        expect(result.errors, isNotEmpty);
        expect(
          result.errors.first.message,
          'Unsupported schema type "unknown".',
        );
        expect(result.schema, isNull);
      });

      test('should log an error for a schema with no type', () {
        final dsbSchema = dsb.Schema.fromMap({});
        final DartanticSchemaAdapterResult result = adapter.adapt(dsbSchema);
        expect(result.errors, isNotEmpty);
        expect(
          result.errors.first.message,
          'Schema must have a "type" or be implicitly typed with '
          '"properties" or "items".',
        );
        expect(result.schema, isNull);
      });

      test('should handle multiple types and use the first one', () {
        final dsbSchema = dsb.Schema.fromMap({
          'type': ['string', 'integer'],
        });
        final DartanticSchemaAdapterResult result = adapter.adapt(dsbSchema);
        expect(result.errors, hasLength(1));
        expect(
          result.errors.first.message,
          'Multiple types found (string, integer). Only the first type '
          '"string" will be used.',
        );
        expect(result.schema, isNotNull);
        expect(result.schema!.schemaMap!['type'], 'string');
      });

      test('should handle an empty type array', () {
        final dsbSchema = dsb.Schema.fromMap({'type': []});
        final DartanticSchemaAdapterResult result = adapter.adapt(dsbSchema);
        expect(result.errors, hasLength(1));
        expect(
          result.errors.first.message,
          'Schema has an empty "type" array.',
        );
        expect(result.schema, isNull);
      });
    });

    group('anyOf', () {
      test('should adapt a schema with anyOf', () {
        final dsbSchema = dsb.Schema.combined(
          anyOf: [
            {
              'properties': {
                'bar': {'type': 'number'},
              },
            },
            {
              'properties': {
                'baz': {'type': 'boolean'},
              },
            },
          ],
        );

        final DartanticSchemaAdapterResult result = adapter.adapt(dsbSchema);

        expect(result.errors, isEmpty);
        expect(result.schema, isNotNull);
        final Map<dynamic, dynamic> schemaMap = result.schema!.schemaMap!;
        expect(schemaMap['anyOf'], isA<List>());
        expect(schemaMap['anyOf'] as List, hasLength(2));
      });

      test('should report an error for an empty anyOf list', () {
        final dsbSchema = dsb.Schema.fromMap({'type': 'object', 'anyOf': []});

        final DartanticSchemaAdapterResult result = adapter.adapt(dsbSchema);

        expect(result.errors, hasLength(1));
        expect(
          result.errors[0].message,
          'The value of "anyOf" must be a non-empty array of schemas.',
        );
      });
    });

    group('Edge Cases', () {
      test('should handle nested objects and arrays', () {
        final dsbSchema = dsb.Schema.object(
          properties: {
            'user': dsb.Schema.object(
              properties: {
                'name': dsb.Schema.string(),
                'roles': dsb.Schema.list(items: dsb.Schema.string()),
              },
              required: ['name'],
            ),
          },
        );

        final DartanticSchemaAdapterResult result = adapter.adapt(dsbSchema);

        expect(result.errors, isEmpty);
        expect(result.schema, isNotNull);
        final Map<dynamic, dynamic> schemaMap = result.schema!.schemaMap!;
        expect(schemaMap['type'], 'object');
        expect(schemaMap['properties'], isA<Map>());
        expect(schemaMap['properties']['user'], isA<Map>());
      });

      test('should handle implicitly typed object schema', () {
        final dsbSchema = dsb.Schema.fromMap({
          'properties': {
            'name': {'type': 'string'},
          },
        });
        final DartanticSchemaAdapterResult result = adapter.adapt(dsbSchema);
        expect(result.errors, isEmpty);
        expect(result.schema, isNotNull);
        expect(result.schema!.schemaMap!['type'], 'object');
      });

      test('should handle implicitly typed array schema', () {
        final dsbSchema = dsb.Schema.fromMap({
          'items': {'type': 'string'},
        });
        final DartanticSchemaAdapterResult result = adapter.adapt(dsbSchema);
        expect(result.errors, isEmpty);
        expect(result.schema, isNotNull);
        expect(result.schema!.schemaMap!['type'], 'array');
      });

      test('should handle an empty object schema', () {
        final dsbSchema = dsb.Schema.object(properties: {});
        final DartanticSchemaAdapterResult result = adapter.adapt(dsbSchema);
        expect(result.errors, isEmpty);
        expect(result.schema, isNotNull);
        expect(result.schema!.schemaMap!['type'], 'object');
      });
    });
  });
}
