// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

void main() {
  testWidgets('Slider widget renders and handles changes', (
    WidgetTester tester,
  ) async {
    final manager = GenUiManager(
      catalog: Catalog([CoreCatalogItems.slider]),
      configuration: const GenUiConfiguration(),
    );
    const surfaceId = 'testSurface';
    final components = [
      const Component(
        id: 'root',
        props: {
          'component': 'Slider',
          'value': {'path': '/myValue'},
          'minValue': {'literalNumber': 0.0},
          'maxValue': {'literalNumber': 1.0},
        },
      ),
    ];
    manager.handleMessage(
      SurfaceUpdate(surfaceId: surfaceId, components: components),
    );
    manager.handleMessage(const CreateSurface(surfaceId: surfaceId));
    manager.dataModelForSurface(surfaceId).update(DataPath('/myValue'), 0.5);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GenUiSurface(host: manager, surfaceId: surfaceId),
        ),
      ),
    );

    final Slider slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.value, 0.5);

    await tester.drag(find.byType(Slider), const Offset(100, 0));
    expect(
      manager
          .dataModelForSurface(surfaceId)
          .getValue<double>(DataPath('/myValue')),
      greaterThan(0.5),
    );
  });

  testWidgets('Slider widget handles data-bound min/max values', (
    WidgetTester tester,
  ) async {
    final manager = GenUiManager(
      catalog: Catalog([CoreCatalogItems.slider]),
      configuration: const GenUiConfiguration(),
    );
    const surfaceId = 'testSurface';
    final components = [
      const Component(
        id: 'root',
        props: {
          'component': 'Slider',
          'value': {'path': '/myValue'},
          'minValue': {'path': '/myMin'},
          'maxValue': {'path': '/myMax'},
        },
      ),
    ];
    manager.handleMessage(
      SurfaceUpdate(surfaceId: surfaceId, components: components),
    );
    manager.handleMessage(const CreateSurface(surfaceId: surfaceId));
    manager.handleMessage(
      const DataModelUpdate(
        surfaceId: surfaceId,
        contents: {'myValue': 5.0, 'myMin': 0.0, 'myMax': 10.0},
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GenUiSurface(host: manager, surfaceId: surfaceId),
        ),
      ),
    );

    final Slider slider = tester.widget(find.byType(Slider));
    expect(slider.value, 5.0);
    expect(slider.min, 0.0);
    expect(slider.max, 10.0);

    // Update min/max via data model
    manager.handleMessage(
      const DataModelUpdate(
        surfaceId: surfaceId,
        contents: {'myMin': 2.0, 'myMax': 8.0},
      ),
    );
    await tester.pumpAndSettle();

    final Slider sliderUpdated = tester.widget(find.byType(Slider));
    expect(sliderUpdated.min, 2.0);
    expect(sliderUpdated.max, 8.0);
  });
}
