// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

List<Object?> requiredOf(CatalogItem item) =>
    item.dataSchema.value['required']! as List<Object?>;

void main() {
  group('CatalogItem.dataSchema', () {
    test('lists component once when the schema already has it', () {
      final CatalogItem original = BasicCatalogItems.button;
      final rebuilt = CatalogItem(
        name: original.name,
        dataSchema: original.dataSchema,
        widgetBuilder: original.widgetBuilder,
      );

      expect(requiredOf(rebuilt).where((p) => p == 'component'), hasLength(1));
      expect(requiredOf(rebuilt), requiredOf(original));
    });

    test('stays the same however many times it is wrapped', () {
      CatalogItem item = BasicCatalogItems.button;
      for (var i = 0; i < 3; i++) {
        item = CatalogItem(
          name: item.name,
          dataSchema: item.dataSchema,
          widgetBuilder: item.widgetBuilder,
        );
      }

      expect(requiredOf(item), requiredOf(BasicCatalogItems.button));
    });
  });

  group('CatalogItem.copyWith', () {
    final item = CatalogItem(
      name: 'Card',
      dataSchema: S.object(
        properties: {'title': S.string()},
        required: ['title'],
      ),
      widgetBuilder: (context) => const SizedBox(),
      exampleData: [() => '[]'],
      isImplicitlyFlexible: true,
    );

    test('keeps every field it is not given', () {
      final CatalogItem copy = item.copyWith();

      expect(copy.name, 'Card');
      expect(copy.dataSchema.value, item.dataSchema.value);
      expect(copy.widgetBuilder, same(item.widgetBuilder));
      expect(copy.exampleData, same(item.exampleData));
      expect(copy.isImplicitlyFlexible, isTrue);
    });

    test('replaces the builder without touching the schema', () {
      Widget wrapped(CatalogItemContext context) => const Placeholder();
      final CatalogItem copy = item.copyWith(widgetBuilder: wrapped);

      expect(copy.widgetBuilder, same(wrapped));
      expect(requiredOf(copy), ['component', 'title']);
    });

    test('a new name renames the component discriminator', () {
      final CatalogItem copy = item.copyWith(name: 'Tile');
      final properties =
          copy.dataSchema.value['properties']! as Map<String, Object?>;

      expect((properties['component']! as Map<String, Object?>)['enum'], [
        'Tile',
      ]);
    });
  });
}
