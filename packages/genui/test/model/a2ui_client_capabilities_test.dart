// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

void main() {
  group('A2UiClientCapabilities.fromCatalogs', () {
    test('handles InlineCatalogHandling.missingIds (default)', () {
      final catalog1 = Catalog([
        BasicCatalogItems.text,
      ], catalogId: 'test_catalog_1');
      final catalog2 = Catalog([BasicCatalogItems.button]);

      final capabilities = A2UiClientCapabilities.fromCatalogs([
        catalog1,
        catalog2,
      ]);

      expect(capabilities.supportedCatalogIds.length, 1);
      expect(capabilities.supportedCatalogIds.first, 'test_catalog_1');

      expect(capabilities.inlineCatalogs, isNotNull);
      expect(capabilities.inlineCatalogs!.length, 1);

      final JsonMap inlineCat = capabilities.inlineCatalogs!.first;
      expect(
        (inlineCat['catalogId'] as String).startsWith('inline_catalog_'),
        isTrue,
      );
      final components = inlineCat['components'] as JsonMap;
      expect(components.containsKey('Button'), isTrue);
    });

    test('handles InlineCatalogHandling.none', () {
      final catalog1 = Catalog([
        BasicCatalogItems.text,
      ], catalogId: 'test_catalog_1');

      final capabilities = A2UiClientCapabilities.fromCatalogs([
        catalog1,
      ], inlineHandling: InlineCatalogHandling.none);

      expect(capabilities.supportedCatalogIds, ['test_catalog_1']);
      expect(capabilities.inlineCatalogs, isNull);
    });

    test(
      'throws StateError for InlineCatalogHandling.none if catalog has no ID',
      () {
        final catalog1 = Catalog([BasicCatalogItems.text]);

        expect(
          () => A2UiClientCapabilities.fromCatalogs([
            catalog1,
          ], inlineHandling: InlineCatalogHandling.none),
          throwsStateError,
        );
      },
    );

    test('handles InlineCatalogHandling.all', () {
      final catalog1 = Catalog([
        BasicCatalogItems.text,
      ], catalogId: 'test_catalog_1');
      final catalog2 = Catalog([BasicCatalogItems.button]);

      final capabilities = A2UiClientCapabilities.fromCatalogs([
        catalog1,
        catalog2,
      ], inlineHandling: InlineCatalogHandling.all);

      expect(capabilities.supportedCatalogIds, isEmpty);
      expect(capabilities.inlineCatalogs, isNotNull);
      expect(capabilities.inlineCatalogs!.length, 2);

      final JsonMap firstCat = capabilities.inlineCatalogs![0];
      final JsonMap secondCat = capabilities.inlineCatalogs![1];

      expect(firstCat['catalogId'], 'test_catalog_1');
      expect(
        (secondCat['catalogId'] as String).startsWith('inline_catalog_'),
        isTrue,
      );
    });

    test('advertises catalog ID aliases alongside the canonical ID', () {
      final catalog = Catalog(
        [BasicCatalogItems.text],
        catalogId: 'canonical',
        catalogIdAliases: const ['legacy', 'older'],
      );

      final capabilities = A2UiClientCapabilities.fromCatalogs([catalog]);

      expect(capabilities.supportedCatalogIds, [
        'canonical',
        'legacy',
        'older',
      ]);
      expect(capabilities.inlineCatalogs, isNull);
    });

    test('advertises both basic catalog IDs by default', () {
      final capabilities = A2UiClientCapabilities.fromCatalogs([
        BasicCatalogItems.asCatalog(),
      ]);

      expect(capabilities.supportedCatalogIds, [
        basicCatalogId,
        // ignore: deprecated_member_use_from_same_package
        legacyBasicCatalogId,
      ]);
    });

    test('advertises each ID once when catalogs share an alias', () {
      final catalog1 = Catalog(
        [BasicCatalogItems.text],
        catalogId: 'first',
        catalogIdAliases: const ['shared'],
      );
      final catalog2 = Catalog(
        [BasicCatalogItems.button],
        catalogId: 'second',
        catalogIdAliases: const ['shared'],
      );

      final capabilities = A2UiClientCapabilities.fromCatalogs([
        catalog1,
        catalog2,
      ]);

      expect(capabilities.supportedCatalogIds, ['first', 'shared', 'second']);
    });

    test('advertises the canonical ID once when an alias repeats it', () {
      final catalog = Catalog(
        [BasicCatalogItems.text],
        catalogId: 'canonical',
        catalogIdAliases: const ['canonical'],
      );

      final capabilities = A2UiClientCapabilities.fromCatalogs([catalog]);

      expect(capabilities.supportedCatalogIds, ['canonical']);
    });

    test('does not advertise aliases when every catalog is inlined', () {
      final catalog = Catalog(
        [BasicCatalogItems.text],
        catalogId: 'canonical',
        catalogIdAliases: const ['legacy'],
      );

      final capabilities = A2UiClientCapabilities.fromCatalogs([
        catalog,
      ], inlineHandling: InlineCatalogHandling.all);

      expect(capabilities.supportedCatalogIds, isEmpty);
      expect(capabilities.inlineCatalogs, hasLength(1));
      expect(capabilities.inlineCatalogs!.single['catalogId'], 'canonical');
    });
  });
}
