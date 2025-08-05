// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Catalog', () {
    testWidgets('buildWidget finds and builds the correct widget', (
      WidgetTester tester,
    ) async {
      final catalog = Catalog([text]);
      final data = {
        'id': 'text1',
        'widget': {
          'text': {'text': 'hello'},
        },
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final widget = catalog.buildWidget(
                  data,
                  (_) => const SizedBox(),
                  (UiEvent event) {},
                  context,
                );
                expect(widget, isA<Text>());
                expect((widget as Text).data, 'hello');
                return widget;
              },
            ),
          ),
        ),
      );
    });

    testWidgets('buildWidget returns empty container for unknown widget type', (
      WidgetTester tester,
    ) async {
      final catalog = const Catalog([]);
      final data = {
        'id': 'text1',
        'widget': {
          'unknown_widget': {'text': 'hello'},
        },
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final widget = catalog.buildWidget(
                  data,
                  (_) => const SizedBox(),
                  (UiEvent event) {},
                  context,
                );
                expect(widget, isA<Container>());
                return widget;
              },
            ),
          ),
        ),
      );
    });

    test('schema generation is correct', () {
      final catalog = Catalog([text, elevatedButtonCatalogItem]);
      final schema = catalog.schema;

      expect(schema.properties?.containsKey('id'), isTrue);
      expect(schema.properties?.containsKey('widget'), isTrue);

      final widgetSchema = schema.properties?['widget'];
      expect(widgetSchema?.properties?.containsKey('text'), isTrue);
      expect(widgetSchema?.properties?.containsKey('elevated_button'), isTrue);
    });
  });
}
