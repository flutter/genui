// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

void main() {
  testWidgets('CheckBox widget renders and handles changes', (
    WidgetTester tester,
  ) async {
    final manager = GenUiManager(
      catalog: Catalog([CoreCatalogItems.checkBox]),
      configuration: const GenUiConfiguration(),
    );
    const surfaceId = 'testSurface';
    final SurfaceController controller = manager.getSurfaceController(
      surfaceId,
    );
    final components = [
      const Component(
        id: 'checkbox',
        componentProperties: {
          'CheckBox': {
            'label': {'literalString': 'Check me'},
            'value': {'path': '/myValue'},
          },
        },
      ),
    ];
    manager.handleMessage(
      SurfaceUpdate(surfaceId: surfaceId, components: components),
    );
    manager.handleMessage(
      const BeginRendering(surfaceId: surfaceId, root: 'checkbox'),
    );
    manager
        .getSurfaceController(surfaceId)
        .dataModel
        .update(DataPath('/myValue'), true);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: GenUiSurface(controller: controller)),
      ),
    );

    expect(find.text('Check me'), findsOneWidget);
    final CheckboxListTile checkbox = tester.widget<CheckboxListTile>(
      find.byType(CheckboxListTile),
    );
    expect(checkbox.value, isTrue);

    await tester.tap(find.byType(CheckboxListTile));
    expect(
      manager
          .getSurfaceController(surfaceId)
          .dataModel
          .getValue<bool>(DataPath('/myValue')),
      isFalse,
    );
  });
}
