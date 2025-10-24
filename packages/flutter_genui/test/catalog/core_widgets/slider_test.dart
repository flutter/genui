// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Slider widget renders and handles changes', (
    WidgetTester tester,
  ) async {
    final manager = GenUiManager(catalog: Catalog([CoreCatalogItems.slider]));
    const surfaceId = 'testSurface';
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
    manager.dataModelForSurface(surfaceId).update('/myValue', 0.5);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GenUiSurface(host: manager, surfaceId: surfaceId),
        ),
      ),
    );

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.value, 0.5);

    await tester.drag(find.byType(Slider), const Offset(100, 0));
    expect(
      manager.dataModelForSurface(surfaceId).getValue<double>('/myValue'),
      greaterThan(0.5),
    );
  });
}
