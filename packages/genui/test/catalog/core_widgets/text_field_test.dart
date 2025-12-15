// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

void main() {
  testWidgets('TextField with no weight in Row defaults to weight: 1 '
      'and expands', (WidgetTester tester) async {
    final a2uiProcessor = A2uiMessageProcessor(
      catalogs: [CoreCatalogItems.asCatalog()],
    );
    const surfaceId = 'testSurface';
    final components = [
      const Component(
        id: 'row',
        componentProperties: {
          'Row': {
            'children': {
              'explicitList': ['text_field'],
            },
          },
        },
      ),
      const Component(
        id: 'text_field',
        componentProperties: {
          'TextField': {
            'label': {'literalString': 'Input'},
          },
        },
        // "weight" property is left unset.
      ),
    ];

    a2uiProcessor.handleMessage(
      SurfaceUpdate(surfaceId: surfaceId, components: components),
    );
    a2uiProcessor.handleMessage(
      const BeginRendering(
        surfaceId: surfaceId,
        root: 'row',
        catalogId: 'a2ui.org:standard_catalog_0_8_0',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GenUiSurface(host: a2uiProcessor, surfaceId: surfaceId),
        ),
      ),
    );

    expect(find.byType(TextField), findsOneWidget);

    final Flexible flexible = tester.widget(
      find.ancestor(
        of: find.byType(TextField),
        matching: find.byType(Flexible),
      ),
    );
    expect(flexible.flex, 1);

    final Finder textFieldFinder = find.byType(TextField);
    final Size size = tester.getSize(textFieldFinder);
    expect(size.width, 800.0);
  });

  testWidgets('TextField in Row (with weight) expands', (
    WidgetTester tester,
  ) async {
    final manager = A2uiMessageProcessor(
      catalogs: [CoreCatalogItems.asCatalog()],
    );
    const surfaceId = 'testSurface';
    final components = [
      const Component(
        id: 'row',
        componentProperties: {
          'Row': {
            'children': {
              'explicitList': ['text_field'],
            },
          },
        },
      ),
      const Component(
        id: 'text_field',
        componentProperties: {
          'TextField': {
            'label': {'literalString': 'Input'},
          },
        },
        weight: 1,
      ),
    ];

    manager.handleMessage(
      SurfaceUpdate(surfaceId: surfaceId, components: components),
    );
    manager.handleMessage(
      const BeginRendering(
        surfaceId: surfaceId,
        root: 'row',
        catalogId: 'a2ui.org:standard_catalog_0_8_0',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GenUiSurface(host: manager, surfaceId: surfaceId),
        ),
      ),
    );

    expect(find.byType(TextField), findsOneWidget);

    expect(
      find.ancestor(
        of: find.byType(TextField),
        matching: find.byType(Flexible),
      ),
      findsOneWidget,
    );

    // Default test screen width is 800.
    final Size size = tester.getSize(find.byType(TextField));
    expect(size.width, 800.0);
  });
}
