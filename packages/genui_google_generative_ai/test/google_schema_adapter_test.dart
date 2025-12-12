// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:genui_google_generative_ai/genui_google_generative_ai.dart';
import 'package:google_cloud_ai_generativelanguage_v1beta/generativelanguage.dart'
    as google_ai;
import 'package:json_schema_builder/json_schema_builder.dart' as dsb;

void main() {
  group('GoogleSchemaAdapter', () {
    late GoogleSchemaAdapter adapter;

    setUp(() {
      adapter = GoogleSchemaAdapter();
    });

    test('adapt converts string schema', () {
      final schema = dsb.S.string();
      final result = adapter.adapt(schema);

      expect(result.schema, isNotNull);
      expect(result.schema!.type, google_ai.Type.string);
      expect(result.errors, isEmpty);
    });

    test('adapt converts number schema', () {
      final schema = dsb.S.number();
      final result = adapter.adapt(schema);

      expect(result.schema, isNotNull);
      expect(result.schema!.type, google_ai.Type.number);
      expect(result.errors, isEmpty);
    });

    test('adapt converts integer schema', () {
      final schema = dsb.S.integer();
      final result = adapter.adapt(schema);

      expect(result.schema, isNotNull);
      expect(result.schema!.type, google_ai.Type.integer);
      expect(result.errors, isEmpty);
    });

    test('adapt converts boolean schema', () {
      final schema = dsb.S.boolean();
      final result = adapter.adapt(schema);

      expect(result.schema, isNotNull);
      expect(result.schema!.type, google_ai.Type.boolean);
      expect(result.errors, isEmpty);
    });

    test('adapt converts object schema with properties', () {
      final schema = dsb.S.object(
        properties: {'name': dsb.S.string(), 'age': dsb.S.integer()},
        required: ['name'],
      );
      final result = adapter.adapt(schema);

      expect(result.schema, isNotNull);
      expect(result.schema!.type, google_ai.Type.object);
      expect(result.schema!.properties, hasLength(2));
      expect(result.schema!.properties['name']!.type, google_ai.Type.string);
      expect(result.schema!.properties['age']!.type, google_ai.Type.integer);
      expect(result.schema!.required, contains('name'));
      expect(result.errors, isEmpty);
    });

    test('adapt converts array schema', () {
      final schema = dsb.S.list(items: dsb.S.string());
      final result = adapter.adapt(schema);

      expect(result.schema, isNotNull);
      expect(result.schema!.type, google_ai.Type.array);
      expect(result.schema!.items, isNotNull);
      expect(result.schema!.items!.type, google_ai.Type.string);
      expect(result.errors, isEmpty);
    });

    test('adapt converts nested object schema', () {
      final schema = dsb.S.object(
        properties: {
          'user': dsb.S.object(
            properties: {'name': dsb.S.string(), 'email': dsb.S.string()},
          ),
        },
      );
      final result = adapter.adapt(schema);

      expect(result.schema, isNotNull);
      expect(result.schema!.type, google_ai.Type.object);
      expect(result.schema!.properties, hasLength(1));
      final userSchema = result.schema!.properties['user']!;
      expect(userSchema.type, google_ai.Type.object);
      expect(userSchema.properties, hasLength(2));
      expect(result.errors, isEmpty);
    });

    test('adapt adds error for unsupported keyword', () {
      final schema = dsb.Schema.fromMap({
        'type': 'string',
        '\$ref': '#/definitions/something',
      });
      final result = adapter.adapt(schema);

      expect(result.schema, isNotNull);
      expect(result.errors, isNotEmpty);
      expect(result.errors.any((e) => e.message.contains('\$ref')), isTrue);
    });

    test('adapt handles string with enum values', () {
      final schema = dsb.S.string(enumValues: ['red', 'green', 'blue']);
      final result = adapter.adapt(schema);

      expect(result.schema, isNotNull);
      expect(result.schema!.type, google_ai.Type.string);
      expect(result.schema!.enum$, isNotNull);
      expect(result.schema!.enum$, hasLength(3));
      expect(result.schema!.enum$, containsAll(['red', 'green', 'blue']));
    });

    test('adapt handles schema with description', () {
      final schema = dsb.S.string(description: 'A test string');
      final result = adapter.adapt(schema);

      expect(result.schema, isNotNull);
      expect(result.schema!.description, 'A test string');
    });

    test('adapt handles schema without type returns error', () {
      final schema = dsb.Schema.fromMap({'description': 'No type'});
      final result = adapter.adapt(schema);

      expect(result.schema, isNull);
      expect(result.errors, isNotEmpty);
    });

    test('adapt adds error for array without items', () {
      final schema = dsb.Schema.fromMap({'type': 'array'});
      final result = adapter.adapt(schema);

      expect(result.schema, isNull);
      expect(result.errors, isNotEmpty);
      expect(result.errors.any((e) => e.message.contains('items')), isTrue);
    });
  });
}
