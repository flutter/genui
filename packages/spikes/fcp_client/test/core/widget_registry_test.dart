// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fcp_client/src/core/widget_catalog_registry.dart';
import 'package:fcp_client/src/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WidgetCatalogRegistry', () {
    final testDefinition = WidgetDefinition.fromMap({
      'properties': <String, Object?>{},
    });

    test('registering and retrieving a builder', () {
      final registry = WidgetCatalogRegistry();
      Widget testBuilder(
        BuildContext context,
        LayoutNode node,
        Map<String, Object?> properties,
        Map<String, List<Widget>> children,
      ) => const SizedBox();

      registry.register(
        CatalogItem(
          name: 'TestWidget',
          builder: testBuilder,
          definition: testDefinition,
        ),
      );

      final retrievedBuilder = registry.getBuilder('TestWidget');
      expect(retrievedBuilder, isNotNull);
      expect(retrievedBuilder, equals(testBuilder));
    });

    test('retrieving a non-existent builder returns null', () {
      final registry = WidgetCatalogRegistry();
      final retrievedBuilder = registry.getBuilder('NonExistentWidget');
      expect(retrievedBuilder, isNull);
    });

    test('overwriting an existing builder', () {
      final registry = WidgetCatalogRegistry();
      Widget builder1(
        BuildContext context,
        LayoutNode node,
        Map<String, Object?> properties,
        Map<String, List<Widget>> children,
      ) => const Text('1');
      Widget builder2(
        BuildContext context,
        LayoutNode node,
        Map<String, Object?> properties,
        Map<String, List<Widget>> children,
      ) => const Text('2');

      registry.register(
        CatalogItem(
          name: 'TestWidget',
          builder: builder1,
          definition: testDefinition,
        ),
      );
      final retrievedBuilder1 = registry.getBuilder('TestWidget');
      expect(retrievedBuilder1, equals(builder1));

      registry.register(
        CatalogItem(
          name: 'TestWidget',
          builder: builder2,
          definition: testDefinition,
        ),
      );
      final retrievedBuilder2 = registry.getBuilder('TestWidget');
      expect(retrievedBuilder2, equals(builder2));
    });

    test('hasBuilder returns correct value', () {
      final registry = WidgetCatalogRegistry();
      Widget testBuilder(
        BuildContext context,
        LayoutNode node,
        Map<String, Object?> properties,
        Map<String, List<Widget>> children,
      ) => const SizedBox();

      expect(registry.hasBuilder('TestWidget'), isFalse);
      registry.register(
        CatalogItem(
          name: 'TestWidget',
          builder: testBuilder,
          definition: testDefinition,
        ),
      );
      expect(registry.hasBuilder('TestWidget'), isTrue);
    });
  });
}
