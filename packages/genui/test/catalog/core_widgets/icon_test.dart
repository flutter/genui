// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

void main() {
  testWidgets('Icon widget renders with literal string', (
    WidgetTester tester,
  ) async {
    final manager = A2uiMessageProcessor(
      catalogs: [
        Catalog([CoreCatalogItems.icon], catalogId: 'test_catalog'),
      ],
    );
    const surfaceId = 'testSurface';
    final components = [
      const Component(
        id: 'icon',
        componentProperties: {
          'Icon': {
            'name': {'literalString': 'add'},
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
        root: 'icon',
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

    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('Icon widget renders with data binding', (
    WidgetTester tester,
  ) async {
    final manager = A2uiMessageProcessor(
      catalogs: [
        Catalog([CoreCatalogItems.icon], catalogId: 'test_catalog'),
      ],
    );
    const surfaceId = 'testSurface';
    final components = [
      const Component(
        id: 'icon',
        componentProperties: {
          'Icon': {
            'name': {'path': '/iconName'},
          },
        },
      ),
    ];
    manager.handleMessage(
      SurfaceUpdate(surfaceId: surfaceId, components: components),
    );
    manager.handleMessage(
      const DataModelUpdate(
        surfaceId: 'testSurface',
        path: '/iconName',
        contents: 'close',
      ),
    );
    manager.handleMessage(
      const BeginRendering(
        surfaceId: surfaceId,
        root: 'icon',
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

    expect(find.byIcon(Icons.close), findsOneWidget);
  });
}
