// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dart_schema_builder/dart_schema_builder.dart' as dsb;
import 'package:firebase_ai/firebase_ai.dart' as firebase_ai;
import 'package:flutter_genui_firebase_ai/flutter_genui_firebase_ai.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GeminiSchemaAdapter', () {
    late GeminiSchemaAdapter adapter;

    setUp(() {
      adapter = GeminiSchemaAdapter();
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

        final result = adapter.adapt(dsbSchema);

        expect(result.errors, isEmpty);
        expect(result.schema, isNotNull);
        expect(result.schema!.type, firebase_ai.SchemaType.object);
        expect(result.schema!.description, 'A person object.');
        expect(result.schema!.properties, hasLength(2));
        expect(
          result.schema!.properties!['name']!.type,
          firebase_ai.SchemaType.string,
        );
        expect(
          result.schema!.properties!['name']!.description,
          'The name of the person.',
        );
        expect(
          result.schema!.properties!['age']!.type,
          firebase_ai.SchemaType.integer,
        );
        expect(
          result.schema!.properties!['age']!.description,
          'The age of the person.',
        );
        expect(result.schema!.optionalProperties, equals(['age']));
      });

      test('should handle unsupported keywords and log errors', () {
        final dsbSchema = dsb.Schema.object(
          properties: {'name': dsb.Schema.string()},
          minProperties: 1,
          maxProperties: 5,
          additionalProperties: dsb.Schema.boolean(),
        );

        final result = adapter.adapt(dsbSchema);

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
        expect(result.schema!.type, firebase_ai.SchemaType.object);
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

        final result = adapter.adapt(dsbSchema);

        expect(result.errors, isEmpty);
        expect(result.schema, isNotNull);
        expect(result.schema!.type, firebase_ai.SchemaType.array);
        expect(result.schema!.description, 'A list of items.');
        expect(result.schema!.items, isNotNull);
        expect(result.schema!.items!.type, firebase_ai.SchemaType.string);
        expect(result.schema!.minItems, 1);
        expect(result.schema!.maxItems, 10);
      });

      test('should log an error if items is missing', () {
        final dsbSchema = dsb.Schema.fromMap({'type': 'array'});
        final result = adapter.adapt(dsbSchema);
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

        final result = adapter.adapt(dsbSchema);

        expect(result.errors, hasLength(1));
        expect(
          result.errors[0].message,
          contains('Unsupported keyword "uniqueItems"'),
        );
        expect(result.schema, isNotNull);
        expect(result.schema!.type, firebase_ai.SchemaType.array);
      });
    });

    group('adaptString', () {
      test('should adapt a simple string schema', () {
        final dsbSchema = dsb.Schema.string(
          format: 'email',
          enumValues: ['test@example.com', 'user@example.com'],
          description: 'A choice of fruit.',
        );

        final result = adapter.adapt(dsbSchema);

        expect(result.errors, isEmpty);
        expect(result.schema, isNotNull);
        expect(result.schema!.type, firebase_ai.SchemaType.string);
        expect(result.schema!.description, 'A choice of fruit.');
        expect(result.schema!.format, 'email');
        expect(result.schema!.enumValues, [
          'test@example.com',
          'user@example.com',
        ]);
      });

      test('should handle unsupported keywords and log errors', () {
        final dsbSchema = dsb.Schema.string(
          minLength: 1,
          maxLength: 10,
          pattern: r'^[a-zA-Z]+$',
        );

        final result = adapter.adapt(dsbSchema);

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
        expect(result.schema!.type, firebase_ai.SchemaType.string);
      });
    });

    group('adaptNumber', () {
      test('should adapt a simple number schema', () {
        final dsbSchema = dsb.Schema.number(minimum: 0.0, maximum: 100.0);

        final result = adapter.adapt(dsbSchema);

        expect(result.errors, isEmpty);
        expect(result.schema, isNotNull);
        expect(result.schema!.type, firebase_ai.SchemaType.number);
        expect(result.schema!.minimum, 0.0);
        expect(result.schema!.maximum, 100.0);
      });

      test('should handle unsupported keywords and log errors', () {
        final dsbSchema = dsb.Schema.number(
          exclusiveMinimum: 0.0,
          exclusiveMaximum: 100.0,
          multipleOf: 5.0,
        );

        final result = adapter.adapt(dsbSchema);

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
        expect(result.schema!.type, firebase_ai.SchemaType.number);
      });
    });

    group('adaptInteger', () {
      test('should adapt a simple integer schema', () {
        final dsbSchema = dsb.Schema.integer(minimum: 0, maximum: 100);

        final result = adapter.adapt(dsbSchema);

        expect(result.errors, isEmpty);
        expect(result.schema, isNotNull);
        expect(result.schema!.type, firebase_ai.SchemaType.integer);
        expect(result.schema!.minimum, 0.0);
        expect(result.schema!.maximum, 100.0);
      });

      test('should handle unsupported keywords and log errors', () {
        final dsbSchema = dsb.Schema.integer(
          exclusiveMinimum: 0,
          exclusiveMaximum: 100,
          multipleOf: 5,
        );

        final result = adapter.adapt(dsbSchema);

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
        expect(result.schema!.type, firebase_ai.SchemaType.integer);
      });
    });

    group('adaptBoolean', () {
      test('should adapt a boolean schema', () {
        final dsbSchema = dsb.Schema.boolean();
        final result = adapter.adapt(dsbSchema);
        expect(result.errors, isEmpty);
        expect(result.schema, isNotNull);
        expect(result.schema!.type, firebase_ai.SchemaType.boolean);
      });
    });

    group('adaptNull', () {
      test('should adapt a null schema to a nullable object', () {
        final dsbSchema = dsb.Schema.nil();
        final result = adapter.adapt(dsbSchema);
        expect(result.schema, isNotNull);
        expect(result.schema!.type, firebase_ai.SchemaType.object);
        expect(result.schema!.nullable, isTrue);
      });
    });

    group('General Error Handling', () {
      test('should log an error for an unknown type', () {
        final dsbSchema = dsb.Schema.fromMap({'type': 'unknown'});
        final result = adapter.adapt(dsbSchema);
        expect(result.errors, isNotEmpty);
        expect(
          result.errors.first.message,
          'Unsupported schema type "unknown".',
        );
        expect(result.schema, isNull);
      });

      test('should log an error for a schema with no type', () {
        final dsbSchema = dsb.Schema.fromMap({});
        final result = adapter.adapt(dsbSchema);
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
        final result = adapter.adapt(dsbSchema);
        expect(result.errors, hasLength(1));
        expect(
          result.errors.first.message,
          'Multiple types found (string, integer). Only the first type '
          '"string" will be used.',
        );
        expect(result.schema, isNotNull);
        expect(result.schema!.type, firebase_ai.SchemaType.string);
      });

      test('should handle an empty type array', () {
        final dsbSchema = dsb.Schema.fromMap({'type': []});
        final result = adapter.adapt(dsbSchema);
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

        final result = adapter.adapt(dsbSchema);

        expect(result.errors, isEmpty);
        expect(result.schema, isNotNull);
        expect(result.schema!.type, firebase_ai.SchemaType.anyOf);
        expect(result.schema!.properties, isNull);
        expect(result.schema!.anyOf, isNotNull);
        expect(result.schema!.anyOf, hasLength(2));
        final firstAnyOf = result.schema!.anyOf![0];
        expect(firstAnyOf.type, firebase_ai.SchemaType.object);
        expect(firstAnyOf.properties, hasLength(1));
        expect(
          firstAnyOf.properties!['bar']!.type,
          firebase_ai.SchemaType.number,
        );
        final secondAnyOf = result.schema!.anyOf![1];
        expect(secondAnyOf.type, firebase_ai.SchemaType.object);
        expect(secondAnyOf.properties, hasLength(1));
        expect(
          secondAnyOf.properties!['baz']!.type,
          firebase_ai.SchemaType.boolean,
        );
      });

      test('should report an error for an empty anyOf list', () {
        final dsbSchema = dsb.Schema.fromMap({'type': 'object', 'anyOf': []});

        final result = adapter.adapt(dsbSchema);

        expect(result.errors, hasLength(1));
        expect(
          result.errors[0].message,
          'The value of "anyOf" must be a non-empty array of schemas.',
        );
      });

      test('should report an error for a non-list anyOf', () {
        final dsbSchema = dsb.Schema.fromMap({
          'type': 'object',
          'anyOf': 'not-a-list',
        });

        final result = adapter.adapt(dsbSchema);

        expect(result.errors, hasLength(1));
        expect(
          result.errors[0].message,
          'The value of "anyOf" must be a non-empty array of schemas.',
        );
      });

      test('should report an error for invalid item in anyOf list', () {
        final dsbSchema = dsb.Schema.fromMap({
          'type': 'object',
          'anyOf': ['not-a-schema'],
        });

        final result = adapter.adapt(dsbSchema);

        expect(result.errors, hasLength(1));
        expect(
          result.errors[0].message,
          'Schema inside "anyOf" must be an object.',
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

        final result = adapter.adapt(dsbSchema);

        expect(result.errors, isEmpty);
        expect(result.schema, isNotNull);
        final userSchema = result.schema!.properties!['user']!;
        expect(userSchema.type, firebase_ai.SchemaType.object);
        expect(userSchema.properties, hasLength(2));
        expect(userSchema.optionalProperties, equals(['roles']));
        final rolesSchema = userSchema.properties!['roles']!;
        expect(rolesSchema.type, firebase_ai.SchemaType.array);
        expect(rolesSchema.items!.type, firebase_ai.SchemaType.string);
      });

      test('should handle implicitly typed object schema', () {
        final dsbSchema = dsb.Schema.fromMap({
          'properties': {
            'name': {'type': 'string'},
          },
        });
        final result = adapter.adapt(dsbSchema);
        expect(result.errors, isEmpty);
        expect(result.schema, isNotNull);
        expect(result.schema!.type, firebase_ai.SchemaType.object);
      });

      test('should handle implicitly typed array schema', () {
        final dsbSchema = dsb.Schema.fromMap({
          'items': {'type': 'string'},
        });
        final result = adapter.adapt(dsbSchema);
        expect(result.errors, isEmpty);
        expect(result.schema, isNotNull);
        expect(result.schema!.type, firebase_ai.SchemaType.array);
      });

      test('should handle an empty object schema', () {
        final dsbSchema = dsb.Schema.object(properties: {});
        final result = adapter.adapt(dsbSchema);
        expect(result.errors, isEmpty);
        expect(result.schema, isNotNull);
        expect(result.schema!.type, firebase_ai.SchemaType.object);
        expect(result.schema!.properties, isEmpty);
        expect(result.schema!.optionalProperties, isEmpty);
      });

      test('should handle an object with all properties required', () {
        final dsbSchema = dsb.Schema.object(
          properties: {
            'name': dsb.Schema.string(),
            'age': dsb.Schema.integer(),
          },
          required: ['name', 'age'],
        );
        final result = adapter.adapt(dsbSchema);
        expect(result.errors, isEmpty);
        expect(result.schema, isNotNull);
        expect(result.schema!.optionalProperties, isEmpty);
      });

      test('should handle an object with no required properties', () {
        final dsbSchema = dsb.Schema.object(
          properties: {
            'name': dsb.Schema.string(),
            'age': dsb.Schema.integer(),
          },
        );
        final result = adapter.adapt(dsbSchema);
        expect(result.errors, isEmpty);
        expect(result.schema, isNotNull);
        expect(
          result.schema!.optionalProperties,
          unorderedEquals(['name', 'age']),
        );
      });

      test('should handle an array of objects', () {
        final dsbSchema = dsb.Schema.list(
          items: dsb.Schema.object(
            properties: {
              'name': dsb.Schema.string(),
              'value': dsb.Schema.integer(),
            },
            required: ['name'],
          ),
        );
        final result = adapter.adapt(dsbSchema);
        expect(result.errors, isEmpty);
        expect(result.schema, isNotNull);
        expect(result.schema!.type, firebase_ai.SchemaType.array);
        final itemsSchema = result.schema!.items!;
        expect(itemsSchema.type, firebase_ai.SchemaType.object);
        expect(itemsSchema.properties, hasLength(2));
        expect(itemsSchema.optionalProperties, equals(['value']));
      });
    });
  });
}
