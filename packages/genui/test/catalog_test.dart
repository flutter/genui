// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:logging/logging.dart';

void main() {
  group('Catalog', () {
    test('has a catalogId', () {
      final catalog = Catalog([
        CoreCatalogItems.text,
      ], catalogId: 'test_catalog');
      expect(catalog.catalogId, 'test_catalog');
    });

    testWidgets('buildWidget finds and builds the correct widget', (
      WidgetTester tester,
    ) async {
      final catalog = Catalog([CoreCatalogItems.column, CoreCatalogItems.text]);
      final widgetData = {
        'Column': {
          'children': {
            'explicitList': ['child1'],
          },
        },
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return catalog.buildWidget(
                  CatalogItemContext(
                    id: 'col1',
                    data: widgetData,
                    buildChild: (_, [_]) =>
                        const Text(''), // Mock child builder
                    dispatchEvent: (UiEvent event) {},
                    buildContext: context,
                    dataContext: DataContext(DataModel(), '/'),
                    getComponent: (String componentId) => null,
                    surfaceId: 'surfaceId',
                  ),
                );
              },
            ),
          ),
        ),
      );
      expect(find.byType(Column), findsOneWidget);
      final Column column = tester.widget<Column>(find.byType(Column));
      expect(column.children.length, 1);
    });

    testWidgets('buildWidget returns empty container for unknown widget type', (
      WidgetTester tester,
    ) async {
      final catalog = const Catalog([]);
      final Map<String, Object> data = {
        'id': 'text1',
        'widget': {
          'unknown_widget': {'text': 'hello'},
        },
      };

      final Future<void> logFuture = expectLater(
        genUiLogger.onRecord,
        emits(
          isA<LogRecord>().having(
            (e) => e.message,
            'message',
            contains('Item unknown_widget was not found'),
          ),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final Widget widget = catalog.buildWidget(
                  CatalogItemContext(
                    id: data['id'] as String,
                    data: data['widget'] as JsonMap,
                    buildChild: (_, [_]) => const SizedBox(),
                    dispatchEvent: (UiEvent event) {},
                    buildContext: context,
                    dataContext: DataContext(DataModel(), '/'),
                    getComponent: (String componentId) => null,
                    surfaceId: 'surfaceId',
                  ),
                );
                expect(widget, isA<Container>());
                return widget;
              },
            ),
          ),
        ),
      );
      await logFuture;
    });

    test('schema generation is correct', () {
      final catalog = Catalog([CoreCatalogItems.text, CoreCatalogItems.button]);
      final schema = catalog.definition as ObjectSchema;

      expect(schema.properties?.containsKey('components'), isTrue);
      expect(schema.properties?.containsKey('styles'), isTrue);

      final componentsSchema = schema.properties!['components'] as ObjectSchema;
      final Map<String, Schema> componentProperties =
          componentsSchema.properties!;

      expect(componentProperties.keys, contains('Text'));
      expect(componentProperties.keys, contains('Button'));
    });
  });
}
