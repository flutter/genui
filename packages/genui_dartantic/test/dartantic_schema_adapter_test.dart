// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: specify_nonobvious_local_variable_types

import 'package:flutter_test/flutter_test.dart';
import 'package:genui_dartantic/genui_dartantic.dart';
import 'package:json_schema_builder/json_schema_builder.dart' as jsb;

void main() {
  group('adaptSchema', () {
    test('returns null for null input', () {
      expect(adaptSchema(null), isNull);
    });

    test('converts object schema', () {
      final schema = jsb.Schema.object(
        properties: {
          'name': jsb.Schema.string(description: 'The name.'),
          'age': jsb.Schema.integer(),
        },
        required: ['name'],
        description: 'A person.',
      );

      final result = adaptSchema(schema);

      expect(result, isNotNull);
      expect(result!.schemaMap!['type'], 'object');
      expect(result.schemaMap!['description'], 'A person.');
      expect(result.schemaMap!['required'], ['name']);
    });

    test('converts array schema', () {
      final schema = jsb.Schema.list(
        items: jsb.Schema.string(),
        minItems: 1,
        maxItems: 10,
      );

      final result = adaptSchema(schema);

      expect(result, isNotNull);
      expect(result!.schemaMap!['type'], 'array');
      expect(result.schemaMap!['minItems'], 1);
      expect(result.schemaMap!['maxItems'], 10);
    });

    test('converts string schema with enum', () {
      final schema = jsb.Schema.string(
        enumValues: ['a', 'b', 'c'],
        format: 'email',
      );

      final result = adaptSchema(schema);

      expect(result, isNotNull);
      expect(result!.schemaMap!['type'], 'string');
      expect(result.schemaMap!['enum'], ['a', 'b', 'c']);
      expect(result.schemaMap!['format'], 'email');
    });

    test('converts number schema', () {
      final schema = jsb.Schema.number(minimum: 0, maximum: 100);

      final result = adaptSchema(schema);

      expect(result, isNotNull);
      expect(result!.schemaMap!['type'], 'number');
      expect(result.schemaMap!['minimum'], 0);
      expect(result.schemaMap!['maximum'], 100);
    });

    test('converts integer schema', () {
      final schema = jsb.Schema.integer(minimum: 0, maximum: 100);

      final result = adaptSchema(schema);

      expect(result, isNotNull);
      expect(result!.schemaMap!['type'], 'integer');
    });

    test('converts boolean schema', () {
      final schema = jsb.Schema.boolean();

      final result = adaptSchema(schema);

      expect(result, isNotNull);
      expect(result!.schemaMap!['type'], 'boolean');
    });

    test('converts nested schemas', () {
      final schema = jsb.Schema.object(
        properties: {
          'user': jsb.Schema.object(
            properties: {'tags': jsb.Schema.list(items: jsb.Schema.string())},
          ),
        },
      );

      final result = adaptSchema(schema);

      expect(result, isNotNull);
      expect(result!.schemaMap!['type'], 'object');
    });

    test('preserves anyOf', () {
      final schema = jsb.Schema.combined(
        anyOf: [
          {'type': 'string'},
          {'type': 'integer'},
        ],
      );

      final result = adaptSchema(schema);

      expect(result, isNotNull);
      expect(result!.schemaMap!['anyOf'], isA<List<Object?>>());
    });
  });
}
