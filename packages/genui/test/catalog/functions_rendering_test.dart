// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

void main() {
  late SurfaceController controller;
  final testCatalog = Catalog(
    [BasicCatalogItems.text, BasicCatalogItems.column],
    functions: BasicFunctions.all,
    catalogId: 'test_catalog',
  );

  setUp(() {
    controller = SurfaceController(catalogs: [testCatalog]);
  });

  tearDown(() {
    controller.dispose();
  });

  testWidgets('Surface renders function output correctly', (
    WidgetTester tester,
  ) async {
    const surfaceId = 'testSurface';

    // 1. Create surface
    controller.handleMessage(
      const CreateSurface(surfaceId: surfaceId, catalogId: 'test_catalog'),
    );

    // 2. Update data model
    controller.handleMessage(
      const UpdateDataModel(
        surfaceId: surfaceId,
        path: DataPath.root,
        value: {'count': 2},
      ),
    );

    // 3. Update components with a function call
    final components = [
      const Component(
        id: 'root',
        type: 'Column',
        properties: {
          'children': ['cartSummaryText'],
        },
      ),
      const Component(
        id: 'cartSummaryText',
        type: 'Text',
        properties: {
          'text': {
            'call': 'pluralize',
            'args': {
              'count': {'path': '/count'},
              'zero': 'No items',
              'one': 'One item',
              'other': 'Multiple items',
            },
            'returnType': 'string',
          },
        },
      ),
    ];

    controller.handleMessage(
      UpdateComponents(surfaceId: surfaceId, components: components),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Surface(surfaceContext: controller.contextFor(surfaceId)),
      ),
    );
    await tester.pumpAndSettle();

    // We expect "Multiple items" because count is 2.
    expect(find.text('Multiple items'), findsOneWidget);
  });
}
