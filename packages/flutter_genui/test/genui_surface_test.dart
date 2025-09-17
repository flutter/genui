// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final testCatalog = Catalog([
    CoreCatalogItems.elevatedButton,
    CoreCatalogItems.text,
  ]);

  testWidgets('SurfaceWidget builds a widget from a definition', (
    WidgetTester tester,
  ) async {
    final manager = GenUiManager(
      catalog: testCatalog,
      configuration: const GenUiConfiguration(),
    );
    final definition = {
      'root': 'root',
      'widgets': [
        {
          'id': 'root',
          'widget': {
            'ElevatedButton': {'child': 'text'},
          },
        },
        {
          'id': 'text',
          'widget': {
            'Text': {'text': 'Hello'},
          },
        },
      ],
    };
    manager.addOrUpdateSurface('testSurface', definition);

    await tester.pumpWidget(
      MaterialApp(
        home: GenUiSurface(host: manager, surfaceId: 'testSurface'),
      ),
    );

    expect(find.text('Hello'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('SurfaceWidget handles events', (WidgetTester tester) async {
    final manager = GenUiManager(
      catalog: testCatalog,
      configuration: const GenUiConfiguration(),
    );
    final definition = {
      'root': 'root',
      'widgets': [
        {
          'id': 'root',
          'widget': {
            'ElevatedButton': {'child': 'text'},
          },
        },
        {
          'id': 'text',
          'widget': {
            'Text': {'text': 'Hello'},
          },
        },
      ],
    };
    manager.addOrUpdateSurface('testSurface', definition);

    await tester.pumpWidget(
      MaterialApp(
        home: GenUiSurface(host: manager, surfaceId: 'testSurface'),
      ),
    );

    await tester.tap(find.byType(ElevatedButton));
  });
}
