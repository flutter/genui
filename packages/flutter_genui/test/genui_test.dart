// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

void main() {
  group('Catalog', () {
    testWidgets('buildWidget finds and builds the correct widget', (
      WidgetTester tester,
    ) async {
      final catalog = Catalog([CoreCatalogItems.text]);
      final data = {
        'id': 'text1',
        'widget': {
          'Text': {'text': 'hello'},
        },
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final widget = catalog.buildWidget(
                  id: data['id'] as String,
                  widgetData: data['widget'] as JsonMap,
                  buildChild: (_) => const SizedBox(),
                  dispatchEvent: (UiEvent event) {},
                  context: context,
                  valueStore: const {},
                );
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

      final logFuture = expectLater(
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
                final widget = catalog.buildWidget(
                  id: data['id'] as String,
                  widgetData: data['widget'] as JsonMap,
                  buildChild: (_) => const SizedBox(),
                  dispatchEvent: (UiEvent event) {},
                  context: context,
                  valueStore: const {},
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
      final catalog = Catalog([
        CoreCatalogItems.text,
        CoreCatalogItems.elevatedButton,
      ]);
      final schema = catalog.schema as ObjectSchema;

      expect(schema.properties?.containsKey('components'), isTrue);
      expect(schema.properties?.containsKey('styles'), isTrue);

      final componentsSchema = schema.properties!['components'] as ObjectSchema;
      final componentProperties = componentsSchema.properties!;

      expect(componentProperties.keys, contains('Text'));
      expect(componentProperties.keys, contains('ElevatedButton'));
    });
  });
}
