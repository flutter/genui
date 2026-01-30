// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

void main() {
  testWidgets('Modal widget renders and handles taps', (
    WidgetTester tester,
  ) async {
    final manager = A2uiMessageProcessor(
      catalogs: [
        Catalog([
          CoreCatalogItems.modal,
          CoreCatalogItems.button,
          CoreCatalogItems.text,
        ], catalogId: 'test_catalog'),
      ],
    );
    const surfaceId = 'testSurface';
    final components = [
      const Component(
        id: 'root',
        type: 'Modal',
        properties: {'entryPointChild': 'button', 'contentChild': 'text'},
      ),
      const Component(
        id: 'button',
        type: 'Button',
        properties: {
          'child': 'button_text',
          'action': {
            'event': {
              'name': 'showModal',
              'context': {'modalId': 'root'},
            },
          },
        },
      ),
      const Component(
        id: 'button_text',
        type: 'Text',
        properties: {'text': 'Open Modal'},
      ),
      const Component(
        id: 'text',
        type: 'Text',
        properties: {'text': 'This is a modal.'},
      ),
    ];
    manager.handleMessage(
      UpdateComponents(surfaceId: surfaceId, components: components),
    );
    manager.handleMessage(
      const CreateSurface(surfaceId: surfaceId, catalogId: 'test_catalog'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GenUiSurface(host: manager, surfaceId: surfaceId),
        ),
      ),
    );

    expect(find.text('Open Modal'), findsOneWidget);
    expect(find.text('This is a modal.'), findsNothing);

    await tester.tap(find.text('Open Modal'));
    await tester.pumpAndSettle();

    expect(find.text('This is a modal.'), findsOneWidget);
  });
}
