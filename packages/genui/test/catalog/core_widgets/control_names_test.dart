// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

import '../../test_infra/message_builders.dart';

/// Renders one component of the basic catalog and returns once it settles.
Future<SemanticsHandle> show(
  WidgetTester tester,
  List<JsonMap> components,
) async {
  final controller = SurfaceController(
    catalogs: [BasicCatalogItems.asCatalog().copyWith(catalogId: 'names')],
  );
  addTearDown(controller.dispose);
  controller.handleMessage(
    updateComponents(surfaceId: 's', components: components),
  );
  controller.handleMessage(createSurface(surfaceId: 's', catalogId: 'names'));

  final SemanticsHandle handle = tester.ensureSemantics();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Surface(surfaceContext: controller.contextFor('s'))),
    ),
  );
  await tester.pumpAndSettle();
  return handle;
}

void main() {
  testWidgets('the audio player names its button and its sliders', (
    tester,
  ) async {
    final SemanticsHandle handle = await show(tester, [
      component(
        id: 'root',
        type: 'AudioPlayer',
        properties: {'url': 'https://example.com/a.mp3'},
      ),
    ]);

    expect(
      tester.getSemantics(find.byType(IconButton)).getSemanticsData().tooltip,
      isNotEmpty,
      reason: 'the play button announces nothing',
    );
    for (final name in <String>['Playback position', 'Volume']) {
      final SemanticsData data = tester
          .getSemantics(find.bySemanticsLabel(name))
          .getSemanticsData();
      expect(data.flagsCollection.isSlider, isTrue, reason: name);
      expect(data.value, isNotEmpty, reason: name);
    }

    handle.dispose();
  });

  testWidgets('a slider is named by its own label', (tester) async {
    final SemanticsHandle handle = await show(tester, [
      component(
        id: 'root',
        type: 'Slider',
        properties: {'value': 0.5, 'min': 0, 'max': 10, 'label': 'Brightness'},
      ),
    ]);

    // One node: the name, the value, the role and the actions together. The
    // caption above the track is not announced a second time.
    expect(find.bySemanticsLabel('Brightness'), findsOneWidget);
    final SemanticsData data = tester
        .getSemantics(find.bySemanticsLabel('Brightness'))
        .getSemanticsData();
    expect(data.flagsCollection.isSlider, isTrue);
    expect(data.value, isNotEmpty);
    expect(data.hasAction(SemanticsAction.increase), isTrue);

    handle.dispose();
  });

  testWidgets('a slider without a label is left as it was', (tester) async {
    final SemanticsHandle handle = await show(tester, [
      component(
        id: 'root',
        type: 'Slider',
        properties: {'value': 0.5, 'min': 0, 'max': 10},
      ),
    ]);

    expect(find.byType(Slider), findsOneWidget);
    expect(tester.takeException(), isNull);

    handle.dispose();
  });
}
