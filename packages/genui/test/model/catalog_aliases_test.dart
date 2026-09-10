// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_core/a2ui_core.dart' as core;
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui/src/model/catalog.dart' show allCoreCatalogsFor;

void main() {
  group('allCoreCatalogsFor', () {
    test('returns a single core catalog when there are no aliases', () {
      final catalog = Catalog([BasicCatalogItems.text], catalogId: 'canonical');

      final List<core.Catalog<core.ComponentApi>> cores = allCoreCatalogsFor(
        catalog,
      );

      expect(cores, hasLength(1));
      expect(cores.single.id, 'canonical');
    });

    test('returns one core catalog per alias, plus the canonical one', () {
      final catalog = Catalog(
        [BasicCatalogItems.text],
        catalogId: 'canonical',
        catalogIdAliases: const ['legacy', 'older'],
      );

      final List<core.Catalog<core.ComponentApi>> cores = allCoreCatalogsFor(
        catalog,
      );

      expect(cores.map((c) => c.id), ['canonical', 'legacy', 'older']);
    });

    test('exposes the same components under every ID', () {
      final catalog = Catalog(
        [BasicCatalogItems.text, BasicCatalogItems.button],
        catalogId: 'canonical',
        catalogIdAliases: const ['legacy'],
      );

      final List<core.Catalog<core.ComponentApi>> cores = allCoreCatalogsFor(
        catalog,
      );

      final Iterable<String> canonicalNames = cores.first.components.keys;
      expect(canonicalNames, containsAll(<String>['Text', 'Button']));
      for (final core.Catalog<core.ComponentApi> aliasCatalog in cores.skip(
        1,
      )) {
        expect(aliasCatalog.components.keys, canonicalNames);
      }
    });

    test('deduplicates an alias that repeats the canonical ID', () {
      final catalog = Catalog(
        [BasicCatalogItems.text],
        catalogId: 'canonical',
        catalogIdAliases: const ['canonical', 'legacy'],
      );

      final List<core.Catalog<core.ComponentApi>> cores = allCoreCatalogsFor(
        catalog,
      );

      expect(cores.map((c) => c.id), ['canonical', 'legacy']);
    });

    test('deduplicates repeated aliases', () {
      final catalog = Catalog(
        [BasicCatalogItems.text],
        catalogId: 'canonical',
        catalogIdAliases: const ['legacy', 'legacy'],
      );

      final List<core.Catalog<core.ComponentApi>> cores = allCoreCatalogsFor(
        catalog,
      );

      expect(cores.map((c) => c.id), ['canonical', 'legacy']);
    });

    test('uses effectiveCatalogId for a catalog without an explicit ID', () {
      final catalog = Catalog([BasicCatalogItems.text]);

      final List<core.Catalog<core.ComponentApi>> cores = allCoreCatalogsFor(
        catalog,
      );

      expect(cores.single.id, catalog.effectiveCatalogId);
      expect(cores.single.id, startsWith('inline_catalog_'));
    });
  });

  group('basic catalog IDs', () {
    test('basicCatalogId is the canonical spec URL', () {
      expect(
        basicCatalogId,
        'https://a2ui.org/specification/v0_9/catalogs/basic/catalog.json',
      );
    });

    test('the basic catalog matches both the canonical and legacy IDs', () {
      final Catalog catalog = BasicCatalogItems.asCatalog();

      expect(catalog.catalogId, basicCatalogId);
      expect(catalog.matchesId(basicCatalogId), isTrue);
      // ignore: deprecated_member_use_from_same_package
      expect(catalog.matchesId(legacyBasicCatalogId), isTrue);
    });

    test('the basic catalog rules prompt advertises the canonical ID', () {
      expect(BasicCatalogItems.basicCatalogRules, contains(basicCatalogId));
      // ignore: deprecated_member_use_from_same_package
      expect(
        BasicCatalogItems.basicCatalogRules,
        isNot(contains(legacyBasicCatalogId)),
      );
    });
  });
}
