// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:json_schema_builder/src/schema_cache.dart';
import 'package:test/test.dart';

/// A registry whose remote fetches are served by [responses] instead of the
/// network.
SchemaRegistry _registryServing(Map<String, Object?> responses) {
  final client = MockClient((http.Request request) async {
    final Object? body = responses[request.url.toString()];
    if (body == null) return http.Response('Not found', 404);
    return http.Response(jsonEncode(body), 200);
  });
  return SchemaRegistry(schemaCache: SchemaCache(httpClient: client));
}

void main() {
  final personSchema = Schema.fromMap({
    'type': 'object',
    'properties': {
      'name': {'type': 'string', 'minLength': 1},
      'age': {'type': 'integer', 'minimum': 0},
    },
    'required': ['name'],
  });

  group('validateSync', () {
    test('accepts valid data', () {
      expect(personSchema.validateSync({'name': 'Ada', 'age': 36}), isEmpty);
    });

    test('reports the same errors as validate', () async {
      const Object data = {'age': -1};
      final List<ValidationError> asyncErrors = await personSchema.validate(
        data,
      );
      final List<ValidationError> syncErrors = personSchema.validateSync(data);

      expect(syncErrors, isNotEmpty);
      expect(
        syncErrors.map((ValidationError e) => e.toErrorString()),
        asyncErrors.map((ValidationError e) => e.toErrorString()),
      );
    });

    test('honors strictFormat', () {
      final schema = Schema.fromMap({'type': 'string', 'format': 'email'});

      expect(schema.validateSync('not-an-email'), isEmpty);
      expect(
        schema
            .validateSync('not-an-email', strictFormat: true)
            .map((ValidationError e) => e.error),
        [ValidationErrorType.formatInvalid],
      );
    });

    test('resolves references within the schema', () {
      final schema = Schema.fromMap({
        r'$defs': {
          'positiveInt': {'type': 'integer', 'minimum': 1},
        },
        'type': 'array',
        'items': {r'$ref': r'#/$defs/positiveInt'},
      });

      expect(schema.validateSync([1, 2, 3]), isEmpty);
      expect(schema.validateSync([1, 0]), isNotEmpty);
      expect(schema.validateSync([1, 'two']), isNotEmpty);
    });

    test('resolves references to schemas in the registry', () {
      final registry = SchemaRegistry()
        ..addSchema(
          Uri.parse('https://example.com/name.json'),
          Schema.fromMap({'type': 'string', 'minLength': 1}),
        );
      final schema = Schema.fromMap({
        'type': 'object',
        'properties': {
          'name': {r'$ref': 'https://example.com/name.json'},
        },
      });

      expect(
        schema.validateSync({'name': 'Ada'}, schemaRegistry: registry),
        isEmpty,
      );
      expect(
        schema.validateSync({'name': ''}, schemaRegistry: registry),
        isNotEmpty,
      );
    });

    test('throws when a reference would have to be fetched', () {
      final schema = Schema.fromMap({
        'type': 'object',
        'properties': {
          'name': {r'$ref': 'https://example.com/name.json'},
        },
      });

      expect(
        () => schema.validateSync({'name': 'Ada'}),
        throwsA(
          isA<SchemaResolutionRequiredException>().having(
            (SchemaResolutionRequiredException e) => e.uri,
            'uri',
            Uri.parse('https://example.com/name.json'),
          ),
        ),
      );
    });

    test(
      'throws rather than passing data an unfetched schema would reject',
      () {
        final schema = Schema.fromMap({
          r'$ref': 'https://example.com/name.json',
        });

        // Without the reference resolved, this data is unconstrained. Silently
        // treating it as valid would turn a missing fetch into a false pass.
        expect(
          () => schema.validateSync(42),
          throwsA(isA<SchemaResolutionRequiredException>()),
        );
      },
    );

    test('throws when the meta schema would have to be fetched', () {
      final schema = Schema.fromMap({
        r'$schema': 'https://json-schema.org/draft/2020-12/schema',
        'type': 'string',
      });

      expect(
        () => schema.validateSync('hello'),
        throwsA(
          isA<SchemaResolutionRequiredException>().having(
            (SchemaResolutionRequiredException e) => e.uri,
            'uri',
            Uri.parse('https://json-schema.org/draft/2020-12/schema'),
          ),
        ),
      );
    });

    test('succeeds against a registry warmed up by validate', () async {
      final SchemaRegistry registry = _registryServing({
        'https://example.com/name.json': {'type': 'string', 'minLength': 1},
      });
      addTearDown(registry.dispose);
      final schema = Schema.fromMap({
        'type': 'object',
        'properties': {
          'name': {r'$ref': 'https://example.com/name.json'},
        },
      });

      // The synchronous path cannot fetch the reference...
      expect(
        () => schema.validateSync({'name': ''}, schemaRegistry: registry),
        throwsA(isA<SchemaResolutionRequiredException>()),
      );

      // ...but once the asynchronous path has fetched it into the registry,
      // every later validation can be synchronous.
      expect(
        await schema.validate({'name': 'Ada'}, schemaRegistry: registry),
        isEmpty,
      );
      expect(
        schema.validateSync({'name': 'Ada'}, schemaRegistry: registry),
        isEmpty,
      );
      expect(
        schema
            .validateSync({'name': ''}, schemaRegistry: registry)
            .map((ValidationError e) => e.error),
        contains(ValidationErrorType.minLengthNotMet),
      );
    });

    test(
      'asks for a fetch that a previous validation failed to make',
      () async {
        final SchemaRegistry registry = _registryServing(const {});
        addTearDown(registry.dispose);
        final schema = Schema.fromMap({
          'type': 'object',
          'properties': {
            'name': {r'$ref': 'https://example.com/missing.json'},
          },
        });

        // The asynchronous path tries the fetch, which fails, and reports the
        // failure as a reference resolution error.
        final List<ValidationError> asyncErrors = await schema.validate({
          'name': 'Ada',
        }, schemaRegistry: registry);
        expect(
          asyncErrors.map((ValidationError e) => e.error),
          contains(ValidationErrorType.refResolutionError),
        );

        // That failure belongs to the validation that made it, not to the
        // registry: the reference is still unresolved, so the synchronous path
        // still refuses to guess at it.
        expect(
          () => schema.validateSync({'name': 'Ada'}, schemaRegistry: registry),
          throwsA(isA<SchemaResolutionRequiredException>()),
        );
      },
    );

    test('retries a fetch that a previous validation failed to make', () async {
      var attempts = 0;
      final client = MockClient((http.Request request) async {
        attempts++;
        if (attempts == 1) return http.Response('Not found', 404);
        return http.Response(jsonEncode({'type': 'string'}), 200);
      });
      final registry = SchemaRegistry(
        schemaCache: SchemaCache(httpClient: client),
      );
      addTearDown(registry.dispose);
      final schema = Schema.fromMap({
        r'$ref': 'https://example.com/flaky.json',
      });

      expect(
        (await schema.validate(
          1,
          schemaRegistry: registry,
        )).map((ValidationError e) => e.error),
        contains(ValidationErrorType.refResolutionError),
      );
      // The second validation retries the fetch rather than reusing the
      // failure, and this time the schema rejects the data on its merits.
      expect(
        (await schema.validate(
          1,
          schemaRegistry: registry,
        )).map((ValidationError e) => e.error),
        contains(ValidationErrorType.typeMismatch),
      );
      expect(attempts, 2);
    });
  });

  group('validate', () {
    test('still fetches remote references', () async {
      final SchemaRegistry registry = _registryServing({
        'https://example.com/name.json': {'type': 'string', 'minLength': 1},
      });
      addTearDown(registry.dispose);
      final schema = Schema.fromMap({r'$ref': 'https://example.com/name.json'});

      expect(await schema.validate('Ada', schemaRegistry: registry), isEmpty);
      expect(
        (await schema.validate(
          '',
          schemaRegistry: registry,
        )).map((ValidationError e) => e.error),
        contains(ValidationErrorType.minLengthNotMet),
      );
    });

    test('fetches a chain of remote references', () async {
      final SchemaRegistry registry = _registryServing({
        'https://example.com/a.json': {r'$ref': 'https://example.com/b.json'},
        'https://example.com/b.json': {r'$ref': 'https://example.com/c.json'},
        'https://example.com/c.json': {'type': 'integer'},
      });
      addTearDown(registry.dispose);
      final schema = Schema.fromMap({r'$ref': 'https://example.com/a.json'});

      expect(await schema.validate(1, schemaRegistry: registry), isEmpty);
      expect(
        await schema.validate('one', schemaRegistry: registry),
        isNotEmpty,
      );
    });
  });
}
