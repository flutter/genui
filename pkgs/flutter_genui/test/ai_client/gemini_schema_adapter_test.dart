// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dart_schema_builder/dart_schema_builder.dart' as dsb;
import 'package:firebase_ai/firebase_ai.dart' as firebase_ai;
import 'package:flutter_genui/src/ai_client/gemini_schema_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GeminiSchemaAdapter', () {
    late GeminiSchemaAdapter adapter;

    setUp(() {
      adapter = GeminiSchemaAdapter();
    });

    test('adapts a simple object schema', () {
      final dsbSchema = dsb.Schema.object(
        properties: {
          'name': dsb.Schema.string(description: 'The name of the person.'),
          'age': dsb.Schema.integer(description: 'The age of the person.'),
        },
        required: ['name'],
        description: 'A person object.',
      );

      final result = adapter.adapt(dsbSchema);
      final schema = result.schema!;

      expect(result.errors, isEmpty);
      expect(schema.type, firebase_ai.SchemaType.object);
      expect(schema.description, 'A person object.');
      expect(schema.properties, isA<Map<String, firebase_ai.Schema>>());
      expect(schema.properties!.length, 2);
      expect(schema.properties!['name']!.type, firebase_ai.SchemaType.string);
      expect(schema.properties!['name']!.description,
          'The name of the person.');
      expect(schema.properties!['age']!.type, firebase_ai.SchemaType.integer);
      expect(
          schema.properties!['age']!.description, 'The age of the person.');
      expect(schema.optionalProperties, ['age']);
    });

    test('adapts a schema with an array of objects', () {
      final dsbSchema = dsb.Schema.list(
        items: dsb.Schema.object(
          properties: {
            'item': dsb.Schema.string(),
          },
        ),
        description: 'A list of items.',
      );

      final result = adapter.adapt(dsbSchema);
      final schema = result.schema!;

      expect(result.errors, isEmpty);
      expect(schema.type, firebase_ai.SchemaType.array);
      expect(schema.description, 'A list of items.');
      expect(schema.items, isNotNull);
      expect(schema.items!.type, firebase_ai.SchemaType.object);
      expect(schema.items!.properties!.length, 1);
      expect(schema.items!.properties!['item']!.type,
          firebase_ai.SchemaType.string);
    });

    test('adapts a string schema with enum values', () {
      final dsbSchema = dsb.Schema.string(
        enumValues: ['apple', 'banana', 'orange'],
        description: 'A choice of fruit.',
      );

      final result = adapter.adapt(dsbSchema);
      final schema = result.schema!;

      expect(result.errors, isEmpty);
      expect(schema.type, firebase_ai.SchemaType.string);
      expect(schema.description, 'A choice of fruit.');
      expect(schema.enumValues, ['apple', 'banana', 'orange']);
    });

    test('adapts number and integer schemas with ranges', () {
      final dsbSchema = dsb.Schema.object(properties: {
        'number': dsb.Schema.number(minimum: 10.5, maximum: 20.5),
        'integer': dsb.Schema.integer(minimum: 1, maximum: 100),
      });

      final result = adapter.adapt(dsbSchema);
      final schema = result.schema!;

      expect(result.errors, isEmpty);
      expect(schema.properties!['number']!.minimum, 10.5);
      expect(schema.properties!['number']!.maximum, 20.5);
      expect(schema.properties!['integer']!.minimum, 1);
      expect(schema.properties!['integer']!.maximum, 100);
    });

    test('adapts boolean and null schemas', () {
      final dsbSchema = dsb.Schema.object(properties: {
        'is_active': dsb.Schema.boolean(),
        'extra_data': dsb.Schema.nil(),
      });

      final result = adapter.adapt(dsbSchema);
      final schema = result.schema!;

      expect(result.errors, isEmpty);
      expect(schema.properties!['is_active']!.type,
          firebase_ai.SchemaType.boolean);
      expect(schema.properties!['extra_data']!.type,
          firebase_ai.SchemaType.object);
      expect(schema.properties!['extra_data']!.nullable, isTrue);
    });

    test('handles unsupported keywords and reports errors', () {
      final dsbSchema = dsb.Schema.object(
        properties: {
          'name': dsb.Schema.string(pattern: '^[a-zA-Z]+\$'),
        },
        additionalProperties: dsb.Schema.boolean(),
      );

      final result = adapter.adapt(dsbSchema);
      expect(result.errors, isNotEmpty);
      expect(result.errors.length, 2);
      expect(
          result.errors.any((e) =>
              e.message.contains('Unsupported keyword "additionalProperties"')),
          isTrue);
      expect(
          result.errors
              .any((e) => e.message.contains('Unsupported keyword "pattern"')),
          isTrue);
    });

    test('handles schema with multiple types', () {
      final dsbSchema = dsb.Schema.fromMap({
        'type': ['string', 'null'],
      });

      final result = adapter.adapt(dsbSchema);
      final schema = result.schema!;

      expect(result.errors.length, 1);
      expect(result.errors[0].message, contains('Multiple types found'));
      expect(schema.type, firebase_ai.SchemaType.string);
    });

    test('handles implicitly typed object schema', () {
      final dsbSchema = dsb.Schema.fromMap({
        'properties': {
          'implicit': dsb.Schema.string(),
        },
      });

      final result = adapter.adapt(dsbSchema);
      final schema = result.schema!;

      expect(result.errors, isEmpty);
      expect(schema.type, firebase_ai.SchemaType.object);
    });

    test('handles implicitly typed array schema', () {
      final dsbSchema = dsb.Schema.fromMap({
        'items': dsb.Schema.string(),
      });

      final result = adapter.adapt(dsbSchema);
      final schema = result.schema!;

      expect(result.errors, isEmpty);
      expect(schema.type, firebase_ai.SchemaType.array);
    });

    test('returns error for schema with no type or structure', () {
      final dsbSchema = dsb.Schema.fromMap({});
      final result = adapter.adapt(dsbSchema);
      expect(result.schema, isNull);
      expect(result.errors, isNotEmpty);
      expect(result.errors[0].message, contains('must have a "type"'));
    });

    test('returns error for array schema without items', () {
      final dsbSchema = dsb.Schema.list();
      final result = adapter.adapt(dsbSchema);
      expect(result.schema, isNull);
      expect(result.errors, isNotEmpty);
      expect(
          result.errors[0].message, contains('must have an "items" property'));
    });
  });
}
