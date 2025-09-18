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
                  data,
                  (_) => const SizedBox(),
                  (UiEvent event) {},
                  context,
                  {},
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
                  data,
                  (_) => const SizedBox(),
                  (UiEvent event) {},
                  context,
                  {},
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

      expect(schema.properties?.containsKey('id'), isTrue);
      expect(schema.properties?.containsKey('widget'), isTrue);

      final widgetSchema = schema.properties!['widget'] as Schema;
      final widgetSchemaMap = widgetSchema.value;
      final anyOf = widgetSchemaMap['anyOf'] as List<Object?>;
      final widgetProperties = anyOf
          .map((e) => e as Schema)
          .map((e) => e.value)
          .map((e) => e['properties'] as Map<String, Object?>)
          .expand((element) => element.keys)
          .toList();

      expect(widgetProperties, contains('Text'));
      expect(widgetProperties, contains('ElevatedButton'));
    });
  });
}
