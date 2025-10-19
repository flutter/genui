// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Row widget renders children', (WidgetTester tester) async {
    final manager = GenUiManager(
      catalog: Catalog([CoreCatalogItems.row, CoreCatalogItems.text]),
      configuration: const GenUiConfiguration(),
    );
    const surfaceId = 'testSurface';
    final components = [
      const Component(
        id: 'row',
        componentProperties: {
          'Row': {
            'children': {
              'explicitList': ['text1', 'text2'],
            },
          },
        },
      ),
      const Component(
        id: 'text1',
        componentProperties: {
          'Text': {
            'text': {'literalString': 'First'},
          },
        },
      ),
      const Component(
        id: 'text2',
        componentProperties: {
          'Text': {
            'text': {'literalString': 'Second'},
          },
        },
      ),
    ];
    manager.handleMessage(
      SurfaceUpdate(surfaceId: surfaceId, components: components),
    );
    manager.handleMessage(
      const BeginRendering(surfaceId: surfaceId, root: 'row'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GenUiSurface(host: manager, surfaceId: surfaceId),
        ),
      ),
    );

    expect(find.text('First'), findsOneWidget);
    expect(find.text('Second'), findsOneWidget);
  });
}
