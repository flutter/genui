// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_agent/a2ui_agent.dart';
import 'package:a2ui_core/a2ui_core.dart';
import 'package:test/test.dart';

void main() {
  group('ComponentPruningTransformer', () {
    test('keeps only allowlisted components', () {
      final Catalog<ComponentApi> pruned = ComponentPruningTransformer(const [
        'Text',
        'Column',
      ]).transform(MinimalCatalog());

      expect(pruned.components.keys, unorderedEquals(['Text', 'Column']));
    });

    test('leaves the source catalog untouched', () {
      final catalog = MinimalCatalog();
      ComponentPruningTransformer(const ['Text']).transform(catalog);

      expect(catalog.components.keys, contains('Button'));
    });

    test('preserves id, functions and theme schema', () {
      final catalog = MinimalCatalog();
      final Catalog<ComponentApi> pruned = ComponentPruningTransformer(
        const ['Text'],
      ).transform(catalog);

      expect(pruned.id, catalog.id);
      expect(pruned.functions.keys, catalog.functions.keys);
      expect(pruned.themeSchema, isNotNull);
    });

    test('ignores names that are not in the catalog', () {
      final Catalog<ComponentApi> pruned = ComponentPruningTransformer(const [
        'Text',
        'NotAComponent',
      ]).transform(MinimalCatalog());

      expect(pruned.components.keys, ['Text']);
    });
  });

  group('FunctionPruningTransformer', () {
    test('keeps only allowlisted functions', () {
      final Catalog<ComponentApi> pruned = FunctionPruningTransformer(
        const [],
      ).transform(MinimalCatalog());

      expect(pruned.functions, isEmpty);
      expect(pruned.components.keys, isNotEmpty);
    });

    test('keeps a named function', () {
      final Catalog<ComponentApi> pruned = FunctionPruningTransformer(
        const ['capitalize'],
      ).transform(MinimalCatalog());

      expect(pruned.functions.keys, ['capitalize']);
    });
  });

  group('CatalogConfig', () {
    test('applies transformers in order', () {
      final config = CatalogConfig(
        MinimalCatalog(),
        transformers: [
          ComponentPruningTransformer(const ['Text', 'Column', 'Button']),
          ComponentPruningTransformer(const ['Text', 'Column']),
        ],
      );

      expect(
        config.transformedCatalog.components.keys,
        unorderedEquals(['Text', 'Column']),
      );
    });

    test('returns the pristine catalog when there are no transformers', () {
      final config = CatalogConfig(MinimalCatalog());

      expect(
        config.transformedCatalog.components.keys,
        MinimalCatalog().components.keys,
      );
    });

    test('caches the transformed catalog', () {
      final config = CatalogConfig(
        MinimalCatalog(),
        transformers: [ComponentPruningTransformer(const ['Text'])],
      );

      expect(
        identical(config.transformedCatalog, config.transformedCatalog),
        isTrue,
      );
    });
  });
}
