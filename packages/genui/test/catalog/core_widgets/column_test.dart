// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

void main() {
  testWidgets('Column widget renders children', (WidgetTester tester) async {
    final manager = A2uiMessageProcessor(
      catalogs: [
        Catalog([
          CoreCatalogItems.column,
          CoreCatalogItems.text,
        ], catalogId: 'test_catalog'),
      ],
    );
    const surfaceId = 'testSurface';
    final components = [
      const Component(
        id: 'column',
        componentProperties: {
          'Column': {
            'children': {
              'explicitList': ['text1', 'text2'],
            },
          },
        },
      ),
      const Component(
        id: 'text1',
        componentProperties: {
          'Text': {
            'text': {'literalString': 'First'},
          },
        },
      ),
      const Component(
        id: 'text2',
        componentProperties: {
          'Text': {
            'text': {'literalString': 'Second'},
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
        root: 'column',
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

    expect(find.text('First'), findsOneWidget);
    expect(find.text('Second'), findsOneWidget);
  });

  testWidgets('Column widget applies weight property to children', (
    WidgetTester tester,
  ) async {
    final manager = A2uiMessageProcessor(
      catalogs: [
        Catalog([
          CoreCatalogItems.column,
          CoreCatalogItems.text,
        ], catalogId: 'test_catalog'),
      ],
    );
    const surfaceId = 'testSurface';
    final components = [
      const Component(
        id: 'column',
        componentProperties: {
          'Column': {
            'children': {
              'explicitList': ['text1', 'text2', 'text3'],
            },
          },
        },
      ),
      const Component(
        id: 'text1',
        componentProperties: {
          'Text': {
            'text': {'literalString': 'First'},
          },
        },
        weight: 1,
      ),
      const Component(
        id: 'text2',
        componentProperties: {
          'Text': {
            'text': {'literalString': 'Second'},
          },
        },
        weight: 2,
      ),
      const Component(
        id: 'text3',
        componentProperties: {
          'Text': {
            'text': {'literalString': 'Third'},
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
        root: 'column',
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

    expect(find.text('First'), findsOneWidget);
    expect(find.text('Second'), findsOneWidget);
    expect(find.text('Third'), findsOneWidget);

    final List<Flexible> flexibleWidgets = tester
        .widgetList<Flexible>(find.byType(Flexible))
        .toList();
    expect(flexibleWidgets.length, 2);

    // Check flex values
    expect(flexibleWidgets[0].flex, 1);
    expect(flexibleWidgets[1].flex, 2);

    // Check that the correct children are wrapped
    expect(
      find.ancestor(of: find.text('First'), matching: find.byType(Flexible)),
      findsOneWidget,
    );
    expect(
      find.ancestor(of: find.text('Second'), matching: find.byType(Flexible)),
      findsOneWidget,
    );
    expect(
      find.ancestor(of: find.text('Third'), matching: find.byType(Flexible)),
      findsNothing,
    );
  });
}
