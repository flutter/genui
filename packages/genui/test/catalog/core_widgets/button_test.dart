// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

void main() {
  testWidgets('Button widget renders and handles taps', (
    WidgetTester tester,
  ) async {
    ChatMessage? message;
    final manager = A2uiMessageProcessor(
      catalogs: [
        Catalog([
          CoreCatalogItems.button,
          CoreCatalogItems.text,
        ], catalogId: 'test_catalog'),
      ],
    );
    manager.onSubmit.listen((event) => message = event);
    const surfaceId = 'testSurface';
    final components = [
      const Component(
        id: 'button',
        componentProperties: {
          'Button': {
            'child': 'button_text',
            'action': {'name': 'testAction'},
          },
        },
      ),
      const Component(
        id: 'button_text',
        componentProperties: {
          'Text': {
            'text': {'literalString': 'Click Me'},
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
        root: 'button',
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

    final Finder buttonFinder = find.byType(ElevatedButton);
    expect(buttonFinder, findsOneWidget);
    expect(
      find.descendant(of: buttonFinder, matching: find.text('Click Me')),
      findsOneWidget,
    );

    expect(message, null);
    await tester.tap(find.byType(ElevatedButton));
    expect(message, isNotNull);
  });
}
