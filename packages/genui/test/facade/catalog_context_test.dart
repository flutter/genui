// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

void main() {
  final catalog = Catalog([
    BasicCatalogItems.card,
    BasicCatalogItems.text,
    BasicCatalogItems.button,
  ], catalogId: 'test_catalog');

  // A custom item with its own schema description, used to verify the manifest
  // derives its description from the schema (single source of truth).
  final fancyItem = CatalogItem(
    name: 'Fancy',
    dataSchema: S.object(
      description: 'A fancy component for decorative content.',
      properties: {'label': S.string()},
      required: ['label'],
    ),
    widgetBuilder: (_) => const SizedBox.shrink(),
  );
  final metaCatalog = Catalog([fancyItem], catalogId: 'meta_catalog');

  group('CatalogContext.manifest', () {
    test('includes catalog item names and descriptions', () {
      final CatalogManifest manifest = CatalogContext.manifest(catalog);

      expect(
        manifest.items.map((CatalogManifestItem e) => e.name),
        containsAll(<String>['Card', 'Text', 'Button']),
      );

      final CatalogManifestItem card = manifest.items.firstWhere(
        (CatalogManifestItem e) => e.name == 'Card',
      );
      // Don't pin the exact wording (it lives in BasicCatalogItems and may
      // change). The "derives from schema description" test below pins the
      // wiring with a controlled item.
      expect(card.description, isNotEmpty);
      expect(manifest.catalogId, 'test_catalog');
    });

    test('derives the description from the schema description', () {
      final CatalogManifest manifest = CatalogContext.manifest(metaCatalog);
      final CatalogManifestItem item = manifest.items.single;

      expect(item.description, 'A fancy component for decorative content.');
    });

    test('manifest items only carry name and description', () {
      final CatalogManifest manifest = CatalogContext.manifest(catalog);

      for (final CatalogManifestItem item in manifest.items) {
        final Iterable<String> keys = item.toJson().keys;
        expect(keys, containsAll(<String>['name', 'description']));
        expect(keys, hasLength(2));
      }
    });
  });

  group('CatalogContext.loadItems', () {
    test('returns details for the requested items', () {
      final LoadCatalogItemsResult result = CatalogContext.loadItems(
        catalog,
        <String>['Card', 'Text'],
      );

      expect(result.items.map((CatalogItemDetails e) => e.name), <String>[
        'Card',
        'Text',
      ]);
      expect(result.catalogId, 'test_catalog');
    });

    test('loaded schema includes id and component', () {
      final LoadCatalogItemsResult result = CatalogContext.loadItems(
        catalog,
        <String>['Card'],
      );
      final properties =
          result.items.single.schema['properties'] as Map<String, Object?>;

      expect(
        properties.keys,
        containsAll(<String>['id', 'component', 'child']),
      );
    });

    test('loaded schema marks id and component as required', () {
      final LoadCatalogItemsResult result = CatalogContext.loadItems(
        catalog,
        <String>['Card'],
      );
      final required = result.items.single.schema['required'] as List<Object?>;

      expect(required, containsAll(<String>['id', 'component']));
    });

    test('loaded Card schema keeps child as required', () {
      final LoadCatalogItemsResult result = CatalogContext.loadItems(
        catalog,
        <String>['Card'],
      );
      final required = result.items.single.schema['required'] as List<Object?>;

      expect(required, contains('child'));
    });

    test('parses example JSON when valid', () {
      final LoadCatalogItemsResult result = CatalogContext.loadItems(
        catalog,
        <String>['Card'],
      );

      expect(result.items.single.examples, hasLength(1));
      expect(result.items.single.examples.first, isA<List<Object?>>());
    });

    test('identifies the item and example when example JSON is invalid', () {
      final invalidExampleItem = CatalogItem(
        name: 'BrokenCard',
        dataSchema: S.object(),
        widgetBuilder: (_) => const SizedBox.shrink(),
        exampleData: <ExampleBuilderCallback>[
          () => '[]',
          () => '{invalid json',
        ],
      );
      final invalidExampleCatalog = Catalog(<CatalogItem>[
        invalidExampleItem,
      ], catalogId: 'invalid_example_catalog');

      expect(
        () => CatalogContext.loadItems(invalidExampleCatalog, <String>[
          'BrokenCard',
        ]),
        throwsA(
          isA<FormatException>()
              .having(
                (FormatException error) => error.message,
                'message',
                allOf(contains('BrokenCard'), contains('example 1')),
              )
              .having(
                (FormatException error) => error.source,
                'source',
                '{invalid json',
              )
              .having(
                (FormatException error) => error.offset,
                'offset',
                isNotNull,
              ),
        ),
      );
    });

    test('preserves request order and removes duplicates', () {
      final LoadCatalogItemsResult result = CatalogContext.loadItems(
        catalog,
        <String>['Button', 'Card', 'Button'],
      );

      expect(result.items.map((CatalogItemDetails e) => e.name), <String>[
        'Button',
        'Card',
      ]);
    });

    test('throws for unknown catalog item', () {
      expect(
        () => CatalogContext.loadItems(catalog, <String>['NotAComponent']),
        throwsA(
          isA<CatalogItemNotFoundException>()
              .having((e) => e.widgetType, 'widgetType', 'NotAComponent')
              .having((e) => e.catalogId, 'catalogId', 'test_catalog'),
        ),
      );
    });

    test('accepts an empty request', () {
      final LoadCatalogItemsResult result = CatalogContext.loadItems(
        catalog,
        const <String>[],
      );

      expect(result.items, isEmpty);
    });

    test('details carry only name, description, schema, and examples', () {
      final LoadCatalogItemsResult result = CatalogContext.loadItems(
        catalog,
        <String>['Card'],
      );
      final Iterable<String> keys = result.items.single.toJson().keys;

      expect(
        keys,
        containsAll(<String>['name', 'description', 'schema', 'examples']),
      );
      expect(keys, hasLength(4));
    });
  });

  group('CatalogContext.loadCatalogItemsTool', () {
    test('exposes a canonical ToolDefinition for incremental mode', () {
      final ToolDefinition<Map<String, Object?>> tool =
          CatalogContext.loadCatalogItemsTool;

      expect(tool.name, 'loadCatalogItems');
      expect(tool.description, isNotEmpty);
      expect(
        tool.description,
        contains('exact item names from the catalog manifest'),
      );
      expect(tool.description, isNot(contains('"Card"')));

      final Map<String, Object?> schema = tool.inputSchema.value;
      expect(schema['type'], 'object');
      final properties = schema['properties'] as Map<String, Object?>;
      expect(properties.keys, contains('items'));
      expect(schema['required'], contains('items'));
    });
  });
}
