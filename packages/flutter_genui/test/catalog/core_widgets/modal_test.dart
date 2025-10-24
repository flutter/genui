// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Modal widget renders and handles taps', (
    WidgetTester tester,
  ) async {
    final manager = GenUiManager(
      catalog: Catalog([
        CoreCatalogItems.modal,
        CoreCatalogItems.button,
        CoreCatalogItems.text,
      ]),
    );
    const surfaceId = 'testSurface';
    final components = [
      const Component(
        id: 'modal',
        componentProperties: {
          'Modal': {'entryPointChild': 'button', 'contentChild': 'text'},
        },
      ),
      const Component(
        id: 'button',
        componentProperties: {
          'Button': {
            'child': 'button_text',
            'action': {
              'name': 'showModal',
              'context': [
                {
                  'key': 'modalId',
                  'value': {'literalString': 'modal'},
                },
              ],
            },
          },
        },
      ),
      const Component(
        id: 'button_text',
        componentProperties: {
          'Text': {
            'text': {'literalString': 'Open Modal'},
          },
        },
      ),
      const Component(
        id: 'text',
        componentProperties: {
          'Text': {
            'text': {'literalString': 'This is a modal.'},
          },
        },
      ),
    ];
    manager.handleMessage(
      SurfaceUpdate(surfaceId: surfaceId, components: components),
    );
    manager.handleMessage(
      const BeginRendering(surfaceId: surfaceId, root: 'modal'),
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
