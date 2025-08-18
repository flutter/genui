// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ai_client/src/gemini_schema_adapter.dart';
import 'package:dart_schema_builder/dart_schema_builder.dart' as dsb;
import 'package:firebase_ai/firebase_ai.dart' as firebase_ai;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GeminiSchemaAdapter', () {
    late GeminiSchemaAdapter adapter;

    setUp(() {
      adapter = GeminiSchemaAdapter();
    });

    test('adapts a simple object schema', () {
      final schema = dsb.S.object(
        properties: {'name': dsb.S.string(), 'age': dsb.S.integer()},
        required: ['name'],
      );
      final result = adapter.adapt(schema);
      expect(result.errors, isEmpty);
      final adapted = result.schema!;
      expect(adapted.type, firebase_ai.SchemaType.object);
      expect(adapted.properties!.length, 2);
      expect(adapted.properties!['name']!.type, firebase_ai.SchemaType.string);
      expect(adapted.properties!['age']!.type, firebase_ai.SchemaType.integer);
      expect(adapted.optionalProperties, ['age']);
    });

    test('adapts an array schema', () {
      final schema = dsb.S.list(items: dsb.S.string());
      final result = adapter.adapt(schema);
      expect(result.errors, isEmpty);
      final adapted = result.schema!;
      expect(adapted.type, firebase_ai.SchemaType.array);
      expect(adapted.items!.type, firebase_ai.SchemaType.string);
    });

    test('handles unsupported keywords gracefully', () {
      final schema = dsb.Schema.fromMap({
        'type': 'string',
        'minLength': 5, // unsupported
        'pattern': '.*', // unsupported
      });
      final result = adapter.adapt(schema);
      expect(result.errors.length, 2);
      expect(result.errors.first.message, contains('minLength'));
      expect(result.errors.last.message, contains('pattern'));
      final adapted = result.schema!;
      expect(adapted.type, firebase_ai.SchemaType.string);
    });

    test('handles multiple types by picking the first', () {
      final schema = dsb.Schema.fromMap({
        'type': ['string', 'null'],
      });
      final result = adapter.adapt(schema);
      expect(result.errors.length, 1);
      expect(result.errors.first.message, contains('Multiple types found'));
      final adapted = result.schema!;
      expect(adapted.type, firebase_ai.SchemaType.string);
    });

    test('infers object type from properties', () {
      final schema = dsb.S.object(properties: {'key': dsb.S.string()});
      final result = adapter.adapt(schema);
      expect(result.errors, isEmpty);
      expect(result.schema!.type, firebase_ai.SchemaType.object);
    });

    test('infers array type from items', () {
      final schema = dsb.S.list(items: dsb.S.string());
      final result = adapter.adapt(schema);
      expect(result.errors, isEmpty);
      expect(result.schema!.type, firebase_ai.SchemaType.array);
    });

    test('returns error for schema with no type information', () {
      final schema = dsb.Schema.fromMap({'description': 'a schema'});
      final result = adapter.adapt(schema);
      expect(result.errors.length, 1);
      expect(
        result.errors.first.message,
        contains('must have a "type" or be implicitly typed'),
      );
      expect(result.schema, isNull);
    });

    test('returns error for array schema without items', () {
      final schema = dsb.Schema.fromMap({'type': 'array'});
      final result = adapter.adapt(schema);
      expect(result.errors.length, 1);
      expect(
        result.errors.first.message,
        contains('Array schema must have an "items" property'),
      );
      expect(result.schema, isNull);
    });
  });
}
