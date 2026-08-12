// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:a2ui_agent/a2ui_agent.dart';
import 'package:a2ui_core/a2ui_core.dart';
import 'package:test/test.dart';

void main() {
  final String minimalId = MinimalCatalog().id;

  group('catalogToDocument', () {
    test('wraps components in the standard envelope', () {
      final Map<String, dynamic> document = catalogToDocument(MinimalCatalog());

      expect(document['catalogId'], minimalId);
      final components = document['components'] as Map<String, dynamic>;
      final text = components['Text'] as Map<String, dynamic>;
      final allOf = text['allOf'] as List<Object?>;

      expect(allOf.first, {
        r'$ref': r'common_types.json#/$defs/ComponentCommon',
      });
      final body = allOf[1] as Map<String, dynamic>;
      expect((body['properties'] as Map<String, dynamic>)['component'], {
        'const': 'Text',
      });
      expect(body['required'], containsAll(['component', 'text']));
    });

    test('expands REF markers into JSON Schema references', () {
      final Map<String, dynamic> document = catalogToDocument(MinimalCatalog());
      final String encoded = jsonEncode(document);

      expect(encoded, contains(r'common_types.json#/$defs/DynamicString'));
      expect(encoded, isNot(contains('REF:')));
    });

    test('lists functions with their return type', () {
      final Map<String, dynamic> document = catalogToDocument(MinimalCatalog());

      expect((document['functions'] as List).single, {
        'name': 'capitalize',
        'returnType': 'string',
        'parameters': isA<Map<String, dynamic>>(),
      });
    });

    test('includes the theme properties', () {
      final Map<String, dynamic> document = catalogToDocument(MinimalCatalog());

      expect(
        (document['theme'] as Map<String, dynamic>).keys,
        contains('primaryColor'),
      );
    });

    test('flattens allOf composition into one property list', () {
      final Map<String, dynamic> document = catalogToDocument(MinimalCatalog());
      final button =
          (document['components'] as Map<String, dynamic>)['Button']
              as Map<String, dynamic>;
      final body =
          (button['allOf'] as List<Object?>)[1] as Map<String, dynamic>;

      expect(
        (body['properties'] as Map<String, dynamic>).keys,
        containsAll(['component', 'checks', 'child', 'variant', 'action']),
      );
    });
  });

  group('catalogFromDocument', () {
    test('round trips a catalog through its document form', () {
      final Catalog<ComponentApi> restored = catalogFromDocument(
        catalogToDocument(MinimalCatalog()),
      );

      expect(restored.id, minimalId);
      expect(
        restored.components.keys,
        unorderedEquals(MinimalCatalog().components.keys),
      );
      expect(restored.functions.keys, ['capitalize']);
    });

    test('preserves signatures across the round trip', () {
      final Catalog<ComponentApi> restored = catalogFromDocument(
        catalogToDocument(MinimalCatalog()),
      );

      expect(
        signatureOf(
          restored.components['Text']!.schema,
        ).map((parameter) => parameter.label).toList(),
        signatureOf(
          MinimalCatalog().components['Text']!.schema,
        ).map((parameter) => parameter.label).toList(),
      );
    });

    test('preserves properties contributed by a shared fragment', () {
      final Catalog<ComponentApi> restored = catalogFromDocument(
        catalogToDocument(MinimalCatalog()),
      );

      // Button composes the shared `Checkable` fragment via allOf; `checks`
      // must survive the trip through the document.
      expect(
        signatureOf(
          restored.components['Button']!.schema,
        ).map((parameter) => parameter.label).toList(),
        signatureOf(
          MinimalCatalog().components['Button']!.schema,
        ).map((parameter) => parameter.label).toList(),
      );
    });

    test('compiles Express against a restored catalog', () {
      final Catalog<ComponentApi> restored = catalogFromDocument(
        catalogToDocument(MinimalCatalog()),
      );

      final List<AgentToRendererMessage> messages = ExpressCompiler(
        catalogs: [restored],
      ).compile('root = Text("Hi", "h1")');

      expect(
        messages.whereType<UpdateComponentsMessage>().single.components.single,
        {'id': 'root', 'component': 'Text', 'text': 'Hi', 'variant': 'h1'},
      );
    });

    test('rejects a catalog id that contradicts the expected one', () {
      expect(
        () => catalogFromDocument({
          'catalogId': 'actual',
          'components': <String, Object?>{},
        }, catalogId: 'expected'),
        throwsA(
          isA<A2uiValidationError>().having(
            (error) => error.message,
            'message',
            contains('Catalog id mismatch'),
          ),
        ),
      );
    });

    test('rejects a protocol version that contradicts the expected one', () {
      expect(
        () => catalogFromDocument({
          'catalogId': 'c',
          'protocolVersion': 'v1.0',
          'components': <String, Object?>{},
        }, protocolVersion: ProtocolVersion.v09),
        throwsA(
          isA<A2uiValidationError>().having(
            (error) => error.message,
            'message',
            contains('Protocol version mismatch'),
          ),
        ),
      );
    });

    test('supplies the id for a document that predates catalogId', () {
      final Catalog<ComponentApi> catalog = catalogFromDocument({
        'components': <String, Object?>{},
      }, catalogId: 'supplied');

      expect(catalog.id, 'supplied');
    });

    test('rejects a document with no id at all', () {
      expect(
        () => catalogFromDocument({'components': <String, Object?>{}}),
        throwsA(isA<A2uiValidationError>()),
      );
    });

    test('rejects a document with no components object', () {
      expect(
        () => catalogFromDocument({'catalogId': 'c'}),
        throwsA(isA<A2uiValidationError>()),
      );
    });

    test('declaration-only functions refuse to execute', () {
      final Catalog<ComponentApi> restored = catalogFromDocument(
        catalogToDocument(MinimalCatalog()),
      );

      expect(
        () => restored.functions['capitalize']!.execute(
          const {},
          DataContext(DataModel(), (name, args, context) => null, '/'),
        ),
        throwsUnsupportedError,
      );
    });
  });

  group('providers', () {
    test('BundledCatalogProvider loads the minimal catalog for v0.9', () {
      expect(const BundledCatalogProvider().load().id, minimalId);
    });

    test('BundledCatalogProvider rejects a version with no bundle', () {
      expect(
        () => const BundledCatalogProvider(
          protocolVersion: ProtocolVersion.v10,
        ).load(),
        throwsA(isA<A2uiValidationError>()),
      );
    });

    test('InMemoryCatalogProvider builds a catalog from a document', () {
      final Catalog<ComponentApi> catalog = const InMemoryCatalogProvider({
        'catalogId': 'inline',
        'components': {
          'Badge': {
            'properties': {
              'label': {'type': 'string'},
            },
            'required': ['label'],
          },
        },
      }).load();

      expect(catalog.id, 'inline');
      expect(
        signatureOf(catalog.components['Badge']!.schema).single.name,
        'label',
      );
    });

    test('StaticCatalogProvider passes a catalog through', () {
      final catalog = MinimalCatalog();

      expect(StaticCatalogProvider(catalog).load(), same(catalog));
    });

    group('FileSystemCatalogProvider', () {
      late Directory directory;

      setUp(() {
        directory = Directory.systemTemp.createTempSync('a2ui_agent_test');
      });

      tearDown(() => directory.deleteSync(recursive: true));

      File write(String name, String contents) =>
          File('${directory.path}/$name')..writeAsStringSync(contents);

      test('loads a catalog document from disk', () {
        final File file = write(
          'catalog.json',
          jsonEncode(catalogToDocument(MinimalCatalog())),
        );

        expect(FileSystemCatalogProvider(file.path).load().id, minimalId);
      });

      test('reports a missing file', () {
        expect(
          () =>
              FileSystemCatalogProvider('${directory.path}/absent.json').load(),
          throwsA(
            isA<A2uiValidationError>().having(
              (error) => error.message,
              'message',
              contains('not found'),
            ),
          ),
        );
      });

      test('reports malformed JSON', () {
        final File file = write('bad.json', '{not json');

        expect(
          () => FileSystemCatalogProvider(file.path).load(),
          throwsA(
            isA<A2uiValidationError>().having(
              (error) => error.message,
              'message',
              contains('not valid JSON'),
            ),
          ),
        );
      });

      test('CatalogConfig.fromPath loads and transforms', () {
        final File file = write(
          'catalog.json',
          jsonEncode(catalogToDocument(MinimalCatalog())),
        );

        final config = CatalogConfig.fromPath(
          file.path,
          transformers: [
            ComponentPruningTransformer(const ['Text']),
          ],
        );

        expect(config.transformedCatalog.components.keys, ['Text']);
      });
    });
  });
}
