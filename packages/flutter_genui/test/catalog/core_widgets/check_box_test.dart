// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CheckBox widget renders and handles changes', (
    WidgetTester tester,
  ) async {
    final manager = GenUiManager(catalog: Catalog([CoreCatalogItems.checkBox]));
    const surfaceId = 'testSurface';
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
    manager.dataModelForSurface(surfaceId).update('/myValue', true);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GenUiSurface(host: manager, surfaceId: surfaceId),
        ),
      ),
    );

    expect(find.text('Check me'), findsOneWidget);
    final checkbox = tester.widget<CheckboxListTile>(
      find.byType(CheckboxListTile),
    );
    expect(checkbox.value, isTrue);

    await tester.tap(find.byType(CheckboxListTile));
    expect(
      manager.dataModelForSurface(surfaceId).getValue<bool>('/myValue'),
      isFalse,
    );
  });
}
