// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

import 'package:genui/src/primitives/constants.dart';

void main() {
  testWidgets('Divider widget renders', (WidgetTester tester) async {
    final manager = GenUiManager(
      catalogs: [
        Catalog([CoreCatalogItems.divider], catalogId: standardCatalogId),
      ],
    );
    const surfaceId = 'testSurface';
    final components = [
      const Component(id: 'root', props: {'component': 'Divider'}),
    ];
    manager.handleMessage(
      SurfaceUpdate(surfaceId: surfaceId, components: components),
    );
    manager.handleMessage(const CreateSurface(surfaceId: surfaceId));

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
