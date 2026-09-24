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

  /// What assistive technology is handed for the component: the node's own
  /// fields plus everything merged into it.
  SemanticsData dataOf(WidgetTester tester) =>
      tester.getSemantics(find.byType(A2uiAccessibility)).getSemanticsData();

  List<JsonMap> textWith(Object? accessibility) => [
    component(
      id: 'root',
      type: 'Text',
      properties: {'text': 'Status: Active', 'accessibility': ?accessibility},
    ),
  ];

  testWidgets('a label replaces what the component says for itself', (
    tester,
  ) async {
    await pumpSurface(tester, textWith({'label': 'Connection status'}));

    // One node, and it announces the agent's label alone. The component's own
    // text is cleared before it merges up, which is what `accessibility.label`
    // means: the name of the element, not an addition to it.
    expect(dataOf(tester).label, 'Connection status');
    expect(find.text('Status: Active'), findsOneWidget);
  });

  testWidgets('a description becomes the hint', (tester) async {
    await pumpSurface(
      tester,
      textWith({
        'label': 'Connection status',
        'description': 'Updated every few seconds',
      }),
    );

    expect(dataOf(tester).hint, 'Updated every few seconds');
  });

  testWidgets('a bound label reads from the data model', (tester) async {
    await pumpSurface(
      tester,
      textWith({
        'label': {'path': '/announcement'},
      }),
      dataModel: {'announcement': 'Connection lost'},
    );

    expect(dataOf(tester).label, 'Connection lost');
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

    expect(dataOf(tester).label, 'Connection restored');
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

    // The component still renders, announced by its own text alone: with
    // nothing to say, the wrapper adds no node of its own.
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

  testWidgets('an interactive component stays one control', (tester) async {
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

    // A Material control builds a semantics node of its own, so its
    // configuration is never offered for replacement and its label survives.
    // The agent's is announced ahead of it, on the same node, which keeps the
    // role and the action where the name is. Replacing it there is the
    // component's own job: a2ui-project/a2ui#2697.
    final SemanticsData data = dataOf(tester);
    expect(data.label, startsWith('Mute notifications'));
    // The button's own label is still there, behind the agent's, which is the
    // part a component has to fix from the inside.
    expect(data.label, endsWith('Mute'));
    expect(data.hint, 'Silences notifications about this conversation');
    expect(data.flagsCollection.isButton, isTrue);
    expect(data.hasAction(SemanticsAction.tap), isTrue);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
  });
}
