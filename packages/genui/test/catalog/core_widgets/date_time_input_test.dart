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
      catalogs: [
        Catalog([
          CoreCatalogItems.dateTimeInput,
          CoreCatalogItems.text,
        ], catalogId: 'test_catalog'),
      ],
      configuration: const GenUiConfiguration(),
    );
    const surfaceId = 'testSurface';
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
      const BeginRendering(
        surfaceId: surfaceId,
        root: 'datetime',
        catalogId: 'test_catalog',
      ),
    );
    manager
        .dataModelForSurface(surfaceId)
        .update(DataPath('/myDateTime'), '2025-10-15');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GenUiSurface(host: manager, surfaceId: surfaceId),
        ),
      ),
    );

    expect(find.text('2025-10-15'), findsOneWidget);
  });
}
