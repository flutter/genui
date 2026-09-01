// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:math';

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

    test('fetches independent remote references in parallel', () async {
      var inFlight = 0;
      var mostInFlight = 0;
      final bothArrived = Completer<void>();
      final client = MockClient((http.Request request) async {
        inFlight++;
        mostInFlight = max(mostInFlight, inFlight);
        if (inFlight == 2 && !bothArrived.isCompleted) bothArrived.complete();
        // Hold each request open until the other one arrives, so that the two
        // can only both complete if they were made concurrently.
        await bothArrived.future.timeout(
          const Duration(seconds: 5),
          onTimeout: () {},
        );
        inFlight--;
        return http.Response(jsonEncode({'type': 'string'}), 200);
      });
      final registry = SchemaRegistry(
        schemaCache: SchemaCache(httpClient: client),
      );
      addTearDown(registry.dispose);
      final schema = Schema.fromMap({
        'type': 'object',
        'properties': {
          'first': {r'$ref': 'https://example.com/first.json'},
          'second': {r'$ref': 'https://example.com/second.json'},
        },
      });

      expect(
        await schema.validate({
          'first': 'Ada',
          'second': 'Grace',
        }, schemaRegistry: registry),
        isEmpty,
      );
      expect(mostInFlight, 2);
    });

    test('a reference it never reaches does not fail the validation', () async {
      final SchemaRegistry registry = _registryServing(const {});
      addTearDown(registry.dispose);
      final schema = Schema.fromMap({
        'type': 'string',
        r'$defs': {
          'unused': {r'$ref': 'https://example.com/missing.json'},
        },
      });

      // The reference is prefetched and the fetch fails, but nothing validates
      // against it, so the data is still valid.
      expect(await schema.validate('Ada', schemaRegistry: registry), isEmpty);
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
  group('asynchronous helpers', () {
    /// Creates the context that validation of [schema] starts from, the way
    /// the entry points do.
    ValidationContext contextFor(Schema schema, {SchemaRegistry? registry}) {
      final SchemaRegistry schemaRegistry = registry ?? SchemaRegistry();
      final Uri sourceUri = Uri.parse('local://schema');
      schemaRegistry.addSchema(sourceUri, schema);
      return ValidationContext(
        schema,
        sourceUri: sourceUri,
        schemaRegistry: schemaRegistry,
      );
    }

    test('validateSubSchema applies a subschema', () async {
      final ValidationContext context = contextFor(personSchema);

      expect(
        (await validateSubSchema(
          {'type': 'string'},
          'Ada',
          [],
          context,
          [],
        )).isValid,
        isTrue,
      );
      expect(
        (await validateSubSchema(
          {'type': 'string'},
          1,
          [],
          context,
          [],
        )).isValid,
        isFalse,
      );
      // A boolean schema accepts or rejects everything.
      expect(
        (await validateSubSchema(true, 'Ada', [], context, [])).isValid,
        isTrue,
      );
      expect(
        (await validateSubSchema(false, 'Ada', [], context, [])).isValid,
        isFalse,
      );
      // Anything that is not a schema at all constrains nothing.
      expect(
        (await validateSubSchema(42, 'Ada', [], context, [])).isValid,
        isTrue,
      );
    });

    test('validateSchema fetches the references it needs', () async {
      final SchemaRegistry registry = _registryServing({
        'https://example.com/name.json': {'type': 'string', 'minLength': 1},
      });
      addTearDown(registry.dispose);
      final schema = Schema.fromMap({r'$ref': 'https://example.com/name.json'});
      final ValidationContext context = contextFor(schema, registry: registry);

      expect(
        (await schema.validateSchema('Ada', [], context, [schema])).isValid,
        isTrue,
      );
      expect(
        (await schema.validateSchema('', [], context, [
          schema,
        ])).errors.map((ValidationError e) => e.error),
        contains(ValidationErrorType.minLengthNotMet),
      );
    });

    test(
      'validateTypeSpecificKeywords applies the keywords for the type',
      () async {
        final schema = Schema.fromMap({'type': 'integer', 'maximum': 10});
        final ValidationContext context = contextFor(schema);

        expect(
          (await schema.validateTypeSpecificKeywords(5, [], context, [
            schema,
          ])).isValid,
          isTrue,
        );
        expect(
          (await schema.validateTypeSpecificKeywords(11, [], context, [
            schema,
          ])).errors.map((ValidationError e) => e.error),
          contains(ValidationErrorType.maximumExceeded),
        );
      },
    );

    test('validateObject applies the object keywords', () async {
      final ValidationContext context = contextFor(personSchema);

      expect(
        (await personSchema.validateObject(
          {'name': 'Ada'},
          [],
          context,
          [personSchema],
        )).isValid,
        isTrue,
      );
      expect(
        (await personSchema.validateObject(
          {'age': 36},
          [],
          context,
          [personSchema],
        )).errors.map((ValidationError e) => e.error),
        contains(ValidationErrorType.requiredPropertyMissing),
      );
    });

    test('validateList applies the list keywords', () async {
      final schema = Schema.fromMap({
        'type': 'array',
        'minItems': 2,
        'items': {'type': 'integer'},
      });
      final ValidationContext context = contextFor(schema);

      expect(
        (await schema.validateList([1, 2], [], context, [schema])).isValid,
        isTrue,
      );
      expect(
        (await schema.validateList(
          [1],
          [],
          context,
          [schema],
        )).errors.map((ValidationError e) => e.error),
        contains(ValidationErrorType.minItemsNotMet),
      );
    });

    test(
      'resolveRef resolves a local reference and fetches a remote one',
      () async {
        final SchemaRegistry registry = _registryServing({
          'https://example.com/name.json': {'type': 'string'},
        });
        addTearDown(registry.dispose);
        final schema = Schema.fromMap({
          r'$defs': {
            'positiveInt': {'type': 'integer', 'minimum': 1},
          },
        });
        final ValidationContext context = contextFor(
          schema,
          registry: registry,
        );

        final (Schema, Uri)? local = await schema.resolveRef(
          r'#/$defs/positiveInt',
          schema,
          context,
        );
        expect(local?.$1.value, {'type': 'integer', 'minimum': 1});

        final (Schema, Uri)? remote = await schema.resolveRef(
          'https://example.com/name.json',
          schema,
          context,
        );
        expect(remote?.$1.value, {'type': 'string'});
        expect(remote?.$2, Uri.parse('https://example.com/name.json'));

        expect(
          await schema.resolveRef(r'#/$defs/missing', schema, context),
          isNull,
        );
      },
    );

    test('resolveDynamicRef follows the dynamic scope', () async {
      final schema = Schema.fromMap({
        r'$id': 'https://example.com/root.json',
        r'$defs': {
          'item': {r'$dynamicAnchor': 'item', 'type': 'integer'},
        },
      });
      final ValidationContext context = contextFor(schema);

      final (Schema, Uri)? resolved = await schema.resolveDynamicRef('#item', [
        schema,
      ], context);
      expect(resolved?.$1.value, {
        r'$dynamicAnchor': 'item',
        'type': 'integer',
      });

      expect(
        await schema.resolveDynamicRef('#missing', [schema], context),
        isNull,
      );
    });
  });

  group('reference resolution failures', () {
    test(r'reports an unresolvable $dynamicRef', () async {
      final schema = Schema.fromMap({r'$dynamicRef': r'#/$defs/missing'});

      expect(
        (await schema.validate(
          'anything',
        )).map((ValidationError e) => e.toErrorString()),
        contains(contains('Failed to resolve dynamic reference')),
      );
    });

    test('reports a meta schema that cannot be fetched', () async {
      final SchemaRegistry registry = _registryServing(const {});
      addTearDown(registry.dispose);
      final schema = Schema.fromMap({
        r'$schema': 'https://example.com/meta.json',
        'type': 'string',
      });

      expect(
        (await schema.validate(
          'Ada',
          schemaRegistry: registry,
        )).map((ValidationError e) => e.toErrorString()),
        contains(contains('Failed to resolve meta schema')),
      );
    });

    test(
      'keeps every vocabulary for a meta schema that declares none',
      () async {
        final registry = SchemaRegistry()
          ..addSchema(
            Uri.parse('https://example.com/meta.json'),
            Schema.fromMap({'type': 'object'}),
          );
        addTearDown(registry.dispose);
        final schema = Schema.fromMap({
          r'$schema': 'https://example.com/meta.json',
          'type': 'string',
          'minLength': 3,
        });

        // The meta schema has no $vocabulary, so validation keeps all of them
        // and minLength still applies.
        expect(schema.validateSync('abc', schemaRegistry: registry), isEmpty);
        expect(
          schema
              .validateSync('ab', schemaRegistry: registry)
              .map((ValidationError e) => e.error),
          contains(ValidationErrorType.minLengthNotMet),
        );
      },
    );

    test('treats a fetch that produces no schema as unresolved', () async {
      final registry = SchemaRegistry(schemaCache: _EmptySchemaCache());
      addTearDown(registry.dispose);
      final schema = Schema.fromMap({
        r'$ref': 'https://example.com/nothing.json',
      });

      expect(
        (await schema.validate(
          'Ada',
          schemaRegistry: registry,
        )).map((ValidationError e) => e.error),
        contains(ValidationErrorType.refResolutionError),
      );
    });
  });

  group('SchemaRegistry', () {
    test('resolve returns a registered schema, fragment and all', () async {
      final registry = SchemaRegistry();
      addTearDown(registry.dispose);
      registry.addSchema(
        Uri.parse('https://example.com/root.json'),
        Schema.fromMap({
          r'$defs': {
            'name': {'type': 'string'},
          },
        }),
      );

      expect(
        (await registry.resolve(
          Uri.parse(r'https://example.com/root.json#/$defs/name'),
        ))?.value,
        {'type': 'string'},
      );
      expect(
        await registry.resolve(
          Uri.parse(r'https://example.com/root.json#/$defs/missing'),
        ),
        isNull,
      );
    });

    test('resolve fetches a schema it does not hold', () async {
      final SchemaRegistry registry = _registryServing({
        'https://example.com/name.json': {'type': 'string'},
      });
      addTearDown(registry.dispose);

      expect(
        (await registry.resolve(
          Uri.parse('https://example.com/name.json'),
        ))?.value,
        {'type': 'string'},
      );
      // The schema is registered now, so the synchronous path can see it.
      expect(
        registry.resolveSync(Uri.parse('https://example.com/name.json'))?.value,
        {'type': 'string'},
      );
    });

    test('prefetchDependencies fetches a chain of references', () async {
      final SchemaRegistry registry = _registryServing({
        'https://example.com/a.json': {r'$ref': 'https://example.com/b.json'},
        'https://example.com/b.json': {'type': 'integer'},
      });
      addTearDown(registry.dispose);
      final schema = Schema.fromMap({r'$ref': 'https://example.com/a.json'});

      expect(
        await registry.prefetchDependencies(
          schema,
          baseUri: Uri.parse('local://schema'),
        ),
        isEmpty,
      );
      // Both links of the chain are in the registry now, so the synchronous
      // path can see them.
      expect(
        registry.resolveSync(Uri.parse('https://example.com/b.json'))?.value,
        {'type': 'integer'},
      );
    });

    test('prefetchDependencies reports what it could not bring in', () async {
      final SchemaRegistry registry = _registryServing(const {});
      addTearDown(registry.dispose);
      final schema = Schema.fromMap({
        r'$ref': 'https://example.com/missing.json',
      });

      final Map<Uri, SchemaFetchException?> unresolved = await registry
          .prefetchDependencies(schema, baseUri: Uri.parse('local://schema'));

      expect(unresolved.keys, [Uri.parse('https://example.com/missing.json')]);
      expect(unresolved.values.single, isA<SchemaFetchException>());
    });

    test('resolve reports a fetch that produces no schema as null', () async {
      final registry = SchemaRegistry(schemaCache: _EmptySchemaCache());
      addTearDown(registry.dispose);

      expect(
        await registry.resolve(Uri.parse('https://example.com/nothing.json')),
        isNull,
      );
    });
  });

  group('SchemaResolutionRequiredException', () {
    test('names the schema that would have to be fetched', () {
      final exception = SchemaResolutionRequiredException(
        Uri.parse('https://example.com/name.json'),
      );

      expect(exception.toString(), contains('https://example.com/name.json'));
      expect(exception.toString(), contains('SchemaRegistry'));
    });
  });
}

/// A cache whose fetches succeed without producing a schema.
class _EmptySchemaCache extends SchemaCache {
  @override
  Future<Schema?> get(Uri uri) async => null;
}
