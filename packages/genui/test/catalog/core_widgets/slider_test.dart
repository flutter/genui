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
    final SurfaceController controller = manager.getSurfaceController(
      surfaceId,
    );
    final components = [
      const Component(
        id: 'slider',
        componentProperties: {
          'Slider': {
            'value': {'path': '/myValue'},
          },
        },
      ),
    ];
    manager.handleMessage(
      SurfaceUpdate(surfaceId: surfaceId, components: components),
    );
    manager.handleMessage(
      const BeginRendering(surfaceId: surfaceId, root: 'slider'),
    );
    manager
        .getSurfaceController(surfaceId)
        .dataModel
        .update(DataPath('/myValue'), 0.5);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: GenUiSurface(controller: controller)),
      ),
    );

    final Slider slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.value, 0.5);

    await tester.drag(find.byType(Slider), const Offset(100, 0));
    expect(
      manager
          .getSurfaceController(surfaceId)
          .dataModel
          .getValue<double>(DataPath('/myValue')),
      greaterThan(0.5),
    );
  });
}
