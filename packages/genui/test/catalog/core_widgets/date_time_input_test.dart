// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

void main() {
  testWidgets('DateTimeInput widget renders and handles changes', (
    WidgetTester tester,
  ) async {
    final manager = GenUiManager(
      catalog: Catalog([CoreCatalogItems.dateTimeInput]),
      configuration: const GenUiConfiguration(),
    );
    const surfaceId = 'testSurface';
    final SurfaceController controller = manager.getSurfaceController(
      surfaceId,
    );
    final components = [
      const Component(
        id: 'datetime',
        componentProperties: {
          'DateTimeInput': {
            'value': {'path': '/myDateTime'},
          },
        },
      ),
    ];
    manager.handleMessage(
      SurfaceUpdate(surfaceId: surfaceId, components: components),
    );
    manager.handleMessage(
      const BeginRendering(surfaceId: surfaceId, root: 'datetime'),
    );
    manager
        .getSurfaceController(surfaceId)
        .dataModel
        .update(DataPath('/myDateTime'), '2025-10-15');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: GenUiSurface(controller: controller)),
      ),
    );

    expect(find.text('2025-10-15'), findsOneWidget);
  });
}
