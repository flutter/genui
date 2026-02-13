// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

void main() {
  testWidgets('AudioPlayer widget renders and has description in semantics', (
    WidgetTester tester,
  ) async {
    final manager = SurfaceController(
      catalogs: [
        Catalog([CoreCatalogItems.audioPlayer], catalogId: 'test_catalog'),
      ],
    );
    const surfaceId = 'testSurface';
    final components = [
      const Component(
        id: 'root',
        type: 'AudioPlayer',
        properties: {
          'url': 'https://example.com/audio.mp3',
          'description': 'Audio Description',
        },
      ),
    ];
    manager.handleMessage(
      UpdateComponents(surfaceId: surfaceId, components: components),
    );
    manager.handleMessage(
      const CreateSurface(surfaceId: surfaceId, catalogId: 'test_catalog'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Surface(surfaceContext: manager.contextFor(surfaceId)),
        ),
      ),
    );

    expect(find.byType(Placeholder), findsOneWidget);

    // Check for Semantics widget properties directly if find.bySemanticsLabel
    // fails
    final Semantics semantics = tester.widget<Semantics>(
      find
          .ancestor(
            of: find.byType(Placeholder),
            matching: find.byType(Semantics),
          )
          .first,
    );
    expect(semantics.properties.label, 'Audio Description');
  });
}
