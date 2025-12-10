// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:logging/logging.dart';

void main() {
  late A2uiMessageProcessor processor;
  final testCatalog = Catalog([
    CoreCatalogItems.button,
    CoreCatalogItems.text,
  ], catalogId: 'test_catalog');

  setUp(() {
    processor = A2uiMessageProcessor(catalogs: [testCatalog]);
  });

  testWidgets('SurfaceWidget builds a widget from a definition', (
    WidgetTester tester,
  ) async {
    const surfaceId = 'testSurface';
    final components = [
      const Component(
        id: 'root',
        componentProperties: {
          'Button': {
            'child': 'text',
            'action': {'name': 'testAction'},
          },
        },
      ),
      const Component(
        id: 'text',
        componentProperties: {
          'Text': {
            'text': {'literalString': 'Hello'},
          },
        },
      ),
    ];
    processor.handleMessage(
      SurfaceUpdate(surfaceId: surfaceId, components: components),
    );
    processor.handleMessage(
      const BeginRendering(
        surfaceId: surfaceId,
        root: 'root',
        catalogId: 'test_catalog',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GenUiSurface(host: processor, surfaceId: surfaceId),
      ),
    );

    expect(find.text('Hello'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('SurfaceWidget handles events', (WidgetTester tester) async {
    const surfaceId = 'testSurface';
    final components = [
      const Component(
        id: 'root',
        componentProperties: {
          'Button': {
            'child': 'text',
            'action': {'name': 'testAction'},
          },
        },
      ),
      const Component(
        id: 'text',
        componentProperties: {
          'Text': {
            'text': {'literalString': 'Hello'},
          },
        },
      ),
    ];
    processor.handleMessage(
      SurfaceUpdate(surfaceId: surfaceId, components: components),
    );
    processor.handleMessage(
      const BeginRendering(
        surfaceId: surfaceId,
        root: 'root',
        catalogId: 'test_catalog',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GenUiSurface(host: processor, surfaceId: surfaceId),
      ),
    );

    await tester.tap(find.byType(ElevatedButton));
  });

  testWidgets(
    'SurfaceWidget renders container and logs error on catalog miss',
    (WidgetTester tester) async {
      const surfaceId = 'testSurface';
      final components = [
        const Component(
          id: 'root',
          componentProperties: {
            'Text': {
              'text': {'literalString': 'Hello'},
            },
          },
        ),
      ];
      processor.handleMessage(
        SurfaceUpdate(surfaceId: surfaceId, components: components),
      );
      // Request a catalogId that doesn't exist in the processor.
      processor.handleMessage(
        const BeginRendering(
          surfaceId: surfaceId,
          root: 'root',
          catalogId: 'non_existent_catalog',
        ),
      );

      final logs = <LogRecord>[];
      genUiLogger.onRecord.listen(logs.add);

      await tester.pumpWidget(
        MaterialApp(
          home: GenUiSurface(host: processor, surfaceId: surfaceId),
        ),
      );

      // Should build an empty container instead of the widget tree.
      expect(find.byType(Container), findsOneWidget);
      expect(find.byType(Text), findsNothing);

      // Should log a severe error.
      expect(
        logs.any(
          (r) =>
              r.level == Level.SEVERE &&
              r.message.contains(
                'Catalog with id "non_existent_catalog" not found',
              ),
        ),
        isTrue,
      );
    },
  );
}
