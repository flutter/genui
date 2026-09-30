// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

import '../../test_infra/message_builders.dart';

void main() {
  testWidgets('Slider widget renders and handles changes', (
    WidgetTester tester,
  ) async {
    final surfaceController = SurfaceController(
      catalogs: [
        Catalog([BasicCatalogItems.slider], catalogId: 'test_catalog'),
      ],
    );
    const surfaceId = 'testSurface';
    final List<JsonMap> components = [
      component(
        id: 'root',
        type: 'Slider',
        properties: {
          'value': {'path': '/myValue'},
        },
      ),
    ];
    surfaceController.handleMessage(
      updateComponents(surfaceId: surfaceId, components: components),
    );
    surfaceController.handleMessage(
      createSurface(surfaceId: surfaceId, catalogId: 'test_catalog'),
    );
    surfaceController
        .contextFor(surfaceId)
        .dataModel
        .update(DataPath('/myValue'), 0.5);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Surface(
            surfaceContext: surfaceController.contextFor(surfaceId),
          ),
        ),
      ),
    );

    final Slider slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.value, 0.5);

    await tester.drag(find.byType(Slider), const Offset(100, 0));
    expect(
      surfaceController
          .contextFor(surfaceId)
          .dataModel
          .getValue<double>(DataPath('/myValue')),
      greaterThan(0.5),
    );
  });

  testWidgets('Slider widget renders label', (WidgetTester tester) async {
    final surfaceController = SurfaceController(
      catalogs: [
        Catalog([BasicCatalogItems.slider], catalogId: 'test_catalog'),
      ],
    );
    const surfaceId = 'testSurface';
    final List<JsonMap> components = [
      component(
        id: 'root',
        type: 'Slider',
        properties: {
          'value': {'path': '/myValue'},
          'label': 'Volume',
        },
      ),
    ];
    surfaceController.handleMessage(
      updateComponents(surfaceId: surfaceId, components: components),
    );
    surfaceController.handleMessage(
      createSurface(surfaceId: surfaceId, catalogId: 'test_catalog'),
    );
    surfaceController
        .contextFor(surfaceId)
        .dataModel
        .update(DataPath('/myValue'), 0.5);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Surface(
            surfaceContext: surfaceController.contextFor(surfaceId),
          ),
        ),
      ),
    );

    expect(find.text('Volume'), findsOneWidget);
  });

  testWidgets('Slider validation checks show error message when failing', (
    WidgetTester tester,
  ) async {
    final surfaceController = SurfaceController(
      catalogs: [BasicCatalogItems.asCatalog()],
    );
    addTearDown(surfaceController.dispose);
    const surfaceId = 'validationTest';
    surfaceController.handleMessage(
      updateDataModel(surfaceId: surfaceId, path: DataPath('/val'), value: 0.2),
    );

    final List<JsonMap> components = [
      component(
        id: 'root',
        type: 'Slider',
        properties: {
          'label': 'Volume',
          'value': {'path': '/val'},
          'checks': [
            {
              'message': 'Must be at least 0.5',
              'condition': {
                'call': 'numeric',
                'args': {
                  'value': {'path': '/val'},
                  'min': 0.5,
                },
              },
            },
          ],
        },
      ),
    ];

    surfaceController.handleMessage(
      updateComponents(surfaceId: surfaceId, components: components),
    );
    surfaceController.handleMessage(
      createSurface(surfaceId: surfaceId, catalogId: basicCatalogId),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Surface(
            surfaceContext: surfaceController.contextFor(surfaceId),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Must be at least 0.5'), findsOneWidget);

    surfaceController.handleMessage(
      updateDataModel(surfaceId: surfaceId, path: DataPath('/val'), value: 0.8),
    );
    await tester.pumpAndSettle();

    expect(find.text('Must be at least 0.5'), findsNothing);
  });
}
