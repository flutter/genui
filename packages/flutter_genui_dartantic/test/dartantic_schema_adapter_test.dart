// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:json_schema_builder/json_schema_builder.dart' as dsb;
import 'package:json_schema/json_schema.dart' as js;

import 'package:flutter_genui_dartantic/flutter_genui_dartantic.dart';

void main() {
  group('DartanticSchemaAdapter', () {
    late DartanticSchemaAdapter adapter;

    setUp(() {
      adapter = DartanticSchemaAdapter();
    });

    test('adapts simple string schema', () {
      final schema = dsb.S.string();
      final result = adapter.adapt(schema);

      expect(result.errors, isEmpty);
      expect(result.schema, isNotNull);
      expect(result.schema!.schemaMap!['type'], equals('string'));
    });

    test('adapts string schema with constraints', () {
      final schema = dsb.S.string(
        minLength: 5,
        maxLength: 100,
        pattern: r'^[a-zA-Z]+$',
        format: 'email',
        enumValues: ['option1', 'option2'],
        description: 'A test string',
      );
      final result = adapter.adapt(schema);

      expect(result.errors, isEmpty);
      expect(result.schema, isNotNull);
      final schemaMap = result.schema!.schemaMap!;
      expect(schemaMap['type'], equals('string'));
      expect(schemaMap['minLength'], equals(5));
      expect(schemaMap['maxLength'], equals(100));
      expect(schemaMap['pattern'], equals(r'^[a-zA-Z]+$'));
      expect(schemaMap['format'], equals('email'));
      expect(schemaMap['enum'], equals(['option1', 'option2']));
      expect(schemaMap['description'], equals('A test string'));
    });

    test('adapts number schema', () {
      final schema = dsb.S.number(
        minimum: 0,
        maximum: 100,
        exclusiveMinimum: 0,
        exclusiveMaximum: 100,
        multipleOf: 5,
        description: 'A test number',
      );
      final result = adapter.adapt(schema);

      expect(result.errors, isEmpty);
      expect(result.schema, isNotNull);
      final schemaMap = result.schema!.schemaMap!;
      expect(schemaMap['type'], equals('number'));
      expect(schemaMap['minimum'], equals(0));
      expect(schemaMap['maximum'], equals(100));
      expect(schemaMap['exclusiveMinimum'], equals(0));
      expect(schemaMap['exclusiveMaximum'], equals(100));
      expect(schemaMap['multipleOf'], equals(5));
      expect(schemaMap['description'], equals('A test number'));
    });

    test('adapts integer schema', () {
      final schema = dsb.S.integer(
        minimum: 0,
        maximum: 100,
        description: 'A test integer',
      );
      final result = adapter.adapt(schema);

      expect(result.errors, isEmpty);
      expect(result.schema, isNotNull);
      final schemaMap = result.schema!.schemaMap!;
      expect(schemaMap['type'], equals('integer'));
      expect(schemaMap['minimum'], equals(0));
      expect(schemaMap['maximum'], equals(100));
      expect(schemaMap['description'], equals('A test integer'));
    });

    test('adapts boolean schema', () {
      final schema = dsb.S.boolean(description: 'A test boolean');
      final result = adapter.adapt(schema);

      expect(result.errors, isEmpty);
      expect(result.schema, isNotNull);
      final schemaMap = result.schema!.schemaMap!;
      expect(schemaMap['type'], equals('boolean'));
      expect(schemaMap['description'], equals('A test boolean'));
    });

    test('adapts null schema', () {
      final schema = dsb.Schema.fromMap({'type': 'null', 'description': 'A test null'});
      final result = adapter.adapt(schema);

      expect(result.errors, isEmpty);
      expect(result.schema, isNotNull);
      final schemaMap = result.schema!.schemaMap!;
      expect(schemaMap['type'], equals('null'));
      expect(schemaMap['description'], equals('A test null'));
    });

    test('adapts object schema', () {
      final schema = dsb.S.object(
        properties: {
          'name': dsb.S.string(),
          'age': dsb.S.integer(),
        },
        required: ['name'],
        description: 'A test object',
      );
      final result = adapter.adapt(schema);

      expect(result.errors, isEmpty);
      expect(result.schema, isNotNull);
      final schemaMap = result.schema!.schemaMap!;
      expect(schemaMap['type'], equals('object'));
      expect(schemaMap['properties'], isA<Map<String, dynamic>>());
      expect(schemaMap['properties']['name']['type'], equals('string'));
      expect(schemaMap['properties']['age']['type'], equals('integer'));
      expect(schemaMap['required'], equals(['name']));
      expect(schemaMap['description'], equals('A test object'));
    });

    test('adapts array schema', () {
      final schema = dsb.Schema.fromMap({
        'type': 'array',
        'items': {'type': 'string'},
        'minItems': 1,
        'maxItems': 10,
        'description': 'A test array',
      });
      final result = adapter.adapt(schema);

      expect(result.errors, isEmpty);
      expect(result.schema, isNotNull);
      final schemaMap = result.schema!.schemaMap!;
      expect(schemaMap['type'], equals('array'));
      expect(schemaMap['items']['type'], equals('string'));
      expect(schemaMap['minItems'], equals(1));
      expect(schemaMap['maxItems'], equals(10));
      expect(schemaMap['description'], equals('A test array'));
    });

    test('adapts anyOf schema', () {
      final schema = dsb.Schema.fromMap({
        'anyOf': [
          {'type': 'string'},
          {'type': 'integer'},
        ],
      });
      final result = adapter.adapt(schema);

      expect(result.errors, isEmpty);
      expect(result.schema, isNotNull);
      final schemaMap = result.schema!.schemaMap!;
      expect(schemaMap['anyOf'], isA<List>());
      expect(schemaMap['anyOf'].length, equals(2));
      expect(schemaMap['anyOf'][0]['type'], equals('string'));
      expect(schemaMap['anyOf'][1]['type'], equals('integer'));
    });

    test('reports errors for unsupported keywords', () {
      final schema = dsb.S.object(
        properties: {
          'test': dsb.S.string(),
        },
        additionalProperties: dsb.S.boolean(),
        patternProperties: {
          'test.*': dsb.S.string(),
        },
        minProperties: 1,
        maxProperties: 5,
      );
      final result = adapter.adapt(schema);

      expect(result.errors, isNotEmpty);
      expect(result.schema, isNotNull);
      
      final errorMessages = result.errors.map((e) => e.message).toList();
      expect(errorMessages, contains('Unsupported keyword "patternProperties". It will be ignored.'));
      expect(errorMessages, contains('Unsupported keyword "additionalProperties". It will be ignored.'));
      expect(errorMessages, contains('Unsupported keyword "minProperties". It will be ignored.'));
      expect(errorMessages, contains('Unsupported keyword "maxProperties". It will be ignored.'));
    });

    test('handles empty type array', () {
      final schema = dsb.Schema.fromMap({'type': []});
      final result = adapter.adapt(schema);

      expect(result.errors, isNotEmpty);
      expect(result.schema, isNull);
      expect(result.errors.first.message, contains('empty "type" array'));
    });

    test('handles multiple types in array', () {
      final schema = dsb.Schema.fromMap({'type': ['string', 'integer']});
      final result = adapter.adapt(schema);

      expect(result.errors, isNotEmpty);
      expect(result.schema, isNotNull);
      expect(result.errors.first.message, contains('Multiple types found'));
      expect(result.schema!.schemaMap!['type'], equals('string'));
    });

    test('handles missing type', () {
      final schema = dsb.Schema.fromMap({});
      final result = adapter.adapt(schema);

      expect(result.errors, isNotEmpty);
      expect(result.schema, isNull);
      expect(result.errors.first.message, contains('must have a "type"'));
    });
  });
}
