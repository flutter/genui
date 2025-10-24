// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Divider widget renders', (WidgetTester tester) async {
    final manager = GenUiManager(catalog: Catalog([CoreCatalogItems.divider]));
    const surfaceId = 'testSurface';
    final components = [
      const Component(
        id: 'divider',
        componentProperties: {'Divider': <String, Object?>{}},
      ),
    ];
    manager.handleMessage(
      SurfaceUpdate(surfaceId: surfaceId, components: components),
    );
    manager.handleMessage(
      const BeginRendering(surfaceId: surfaceId, root: 'divider'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GenUiSurface(host: manager, surfaceId: surfaceId),
        ),
      ),
    );

    expect(find.byType(Divider), findsOneWidget);
  });
}
