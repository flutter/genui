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
        id: 'root',
        type: 'Row',
        properties: {
          'children': ['text_field'],
        },
      ),
      const Component(
        id: 'text_field',
        type: 'TextField',
        properties: {'label': 'Input'},
        // "weight" property is left unset.
      ),
    ];

    a2uiProcessor.handleMessage(
      UpdateComponents(surfaceId: surfaceId, components: components),
    );
    a2uiProcessor.handleMessage(
      const CreateSurface(surfaceId: surfaceId, catalogId: standardCatalogId),
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
        id: 'root',
        type: 'Row',
        properties: {
          'children': ['text_field'],
        },
      ),
      const Component(
        id: 'text_field',
        type: 'TextField',
        properties: {'label': 'Input', 'weight': 1},
      ),
    ];

    manager.handleMessage(
      UpdateComponents(surfaceId: surfaceId, components: components),
    );
    manager.handleMessage(
      const CreateSurface(surfaceId: surfaceId, catalogId: standardCatalogId),
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

  testWidgets('TextField validation checks work', (WidgetTester tester) async {
    final manager = A2uiMessageProcessor(
      catalogs: [CoreCatalogItems.asCatalog()],
    );
    const surfaceId = 'validationTest';
    // Initialize with invalid value
    manager.handleMessage(
      const UpdateDataModel(
        surfaceId: surfaceId,
        path: '/',
        value: {'inputValue': 'short'},
      ),
    );

    final components = [
      const Component(
        id: 'root',
        type: 'TextField',
        properties: {
          'label': 'Input',
          'value': {'path': 'inputValue'},
          'checks': [
            {
              'message': 'Must be at least 6 chars',
              'func': 'length',
              'args': [
                {'path': 'inputValue'},
                {'min': 6},
              ],
            },
          ],
        },
      ),
    ];

    manager.handleMessage(
      UpdateComponents(surfaceId: surfaceId, components: components),
    );
    manager.handleMessage(
      const CreateSurface(surfaceId: surfaceId, catalogId: standardCatalogId),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GenUiSurface(host: manager, surfaceId: surfaceId),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify error text is shown
    expect(find.text('Must be at least 6 chars'), findsOneWidget);

    // Update with valid value
    await tester.enterText(find.byType(TextField), 'valid value');
    await tester.pumpAndSettle();

    expect(find.text('Must be at least 6 chars'), findsNothing);
  });
}
