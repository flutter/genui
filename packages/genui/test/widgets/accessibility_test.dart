// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

import '../test_infra/message_builders.dart';

void main() {
  late SurfaceController controller;
  final testCatalog = Catalog([
    BasicCatalogItems.button,
    BasicCatalogItems.text,
  ], catalogId: 'test_catalog');

  setUp(() {
    controller = SurfaceController(catalogs: [testCatalog]);
  });

  tearDown(() {
    controller.dispose();
  });

  /// Renders [components] as a surface and returns once it has settled.
  Future<void> pumpSurface(
    WidgetTester tester,
    List<JsonMap> components, {
    JsonMap? dataModel,
  }) async {
    const surfaceId = 'testSurface';
    controller.handleMessage(
      updateComponents(surfaceId: surfaceId, components: components),
    );
    controller.handleMessage(
      createSurface(surfaceId: surfaceId, catalogId: 'test_catalog'),
    );
    if (dataModel != null) {
      controller.handleMessage(
        updateDataModel(surfaceId: surfaceId, value: dataModel),
      );
    }
    await tester.pumpWidget(
      MaterialApp(
        home: Surface(surfaceContext: controller.contextFor(surfaceId)),
      ),
    );
    await tester.pumpAndSettle();
  }

  List<JsonMap> textWith(Object? accessibility) => [
    component(
      id: 'root',
      type: 'Text',
      properties: {
        'text': 'Status: Active',
        'accessibility': ?accessibility,
      },
    ),
  ];

  testWidgets('a label is what assistive technology announces', (tester) async {
    await pumpSurface(tester, textWith({'label': 'Connection status'}));

    expect(find.bySemanticsLabel('Connection status'), findsOneWidget);
  });

  testWidgets('a description becomes the hint', (tester) async {
    await pumpSurface(
      tester,
      textWith({
        'label': 'Connection status',
        'description': 'Updated every few seconds',
      }),
    );

    final SemanticsNode node = tester.getSemantics(
      find.bySemanticsLabel('Connection status'),
    );
    expect(node.hint, 'Updated every few seconds');
  });

  testWidgets('a bound label reads from the data model', (tester) async {
    await pumpSurface(
      tester,
      textWith({
        'label': {'path': '/announcement'},
      }),
      dataModel: {'announcement': 'Connection lost'},
    );

    expect(find.bySemanticsLabel('Connection lost'), findsOneWidget);
  });

  testWidgets('a bound label follows the data model', (tester) async {
    await pumpSurface(
      tester,
      textWith({
        'label': {'path': '/announcement'},
      }),
      dataModel: {'announcement': 'Connection lost'},
    );

    controller.handleMessage(
      updateDataModel(
        surfaceId: 'testSurface',
        path: DataPath('/announcement'),
        value: 'Connection restored',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Connection lost'), findsNothing);
    expect(find.bySemanticsLabel('Connection restored'), findsOneWidget);
  });

  testWidgets('a binding that has not resolved announces nothing', (
    tester,
  ) async {
    await pumpSurface(
      tester,
      textWith({
        'label': {'path': '/missing'},
      }),
    );

    // The component still renders, announced by its own text alone.
    expect(find.text('Status: Active'), findsOneWidget);
    expect(
      tester.getSemantics(find.text('Status: Active')).label,
      'Status: Active',
    );
  });

  testWidgets('a component without the attributes is left alone', (
    tester,
  ) async {
    await pumpSurface(tester, textWith(null));

    expect(find.byType(A2uiAccessibility), findsNothing);
    expect(find.text('Status: Active'), findsOneWidget);
  });

  testWidgets('an interactive component keeps its action', (tester) async {
    await pumpSurface(tester, [
      component(
        id: 'root',
        type: 'Button',
        properties: {
          'child': 'label',
          'action': {
            'event': {'name': 'mute'},
          },
          'accessibility': {
            'label': 'Mute notifications',
            'description': 'Silences notifications about this conversation',
          },
        },
      ),
      component(id: 'label', type: 'Text', properties: {'text': 'Mute'}),
    ]);

    expect(find.bySemanticsLabel('Mute notifications'), findsOneWidget);
    // The wrapper describes the button; it does not stand in for it.
    expect(find.byType(ElevatedButton), findsOneWidget);
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
  });
}
