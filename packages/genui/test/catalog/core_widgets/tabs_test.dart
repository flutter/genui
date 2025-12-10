// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

void main() {
  testWidgets('Tabs widget renders and handles taps', (
    WidgetTester tester,
  ) async {
    final manager = A2uiMessageProcessor(
      catalogs: [
        Catalog([
          CoreCatalogItems.tabs,
          CoreCatalogItems.text,
        ], catalogId: 'test_catalog'),
      ],
    );
    const surfaceId = 'testSurface';
    final components = [
      const Component(
        id: 'tabs',
        componentProperties: {
          'Tabs': {
            'tabItems': [
              {
                'title': {'literalString': 'Tab 1'},
                'child': 'text1',
              },
              {
                'title': {'literalString': 'Tab 2'},
                'child': 'text2',
              },
            ],
          },
        },
      ),
      const Component(
        id: 'text1',
        componentProperties: {
          'Text': {
            'text': {'literalString': 'This is the first tab.'},
          },
        },
      ),
      const Component(
        id: 'text2',
        componentProperties: {
          'Text': {
            'text': {'literalString': 'This is the second tab.'},
          },
        },
      ),
    ];
    manager.handleMessage(
      SurfaceUpdate(surfaceId: surfaceId, components: components),
    );
    manager.handleMessage(
      const BeginRendering(
        surfaceId: surfaceId,
        root: 'tabs',
        catalogId: 'test_catalog',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GenUiSurface(host: manager, surfaceId: surfaceId),
        ),
      ),
    );

    expect(find.text('Tab 1'), findsOneWidget);
    expect(find.text('Tab 2'), findsOneWidget);
    expect(find.text('This is the first tab.'), findsOneWidget);
    expect(find.text('This is the second tab.'), findsNothing);

    await tester.tap(find.text('Tab 2'));
    await tester.pumpAndSettle();

    expect(find.text('This is the first tab.'), findsNothing);
    expect(find.text('This is the second tab.'), findsOneWidget);
  });
}
