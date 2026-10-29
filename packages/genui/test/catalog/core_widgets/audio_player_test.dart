// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore: deprecated_member_use, see https://github.com/a2ui-project/a2ui/issues/3235
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

import '../../test_infra/message_builders.dart';

void main() {
  testWidgets('AudioPlayer widget renders and has description in semantics', (
    WidgetTester tester,
  ) async {
    final surfaceController = SurfaceController(
      catalogs: [
        Catalog([BasicCatalogItems.audioPlayer], catalogId: 'test_catalog'),
      ],
    );
    const surfaceId = 'testSurface';
    final List<JsonMap> components = [
      component(
        id: 'root',
        type: 'AudioPlayer',
        properties: {
          'url': 'https://example.com/audio.mp3',
          'description': 'Audio Description',
        },
      ),
    ];
    surfaceController.handleMessage(
      updateComponents(surfaceId: surfaceId, components: components),
    );
    surfaceController.handleMessage(
      createSurface(surfaceId: surfaceId, catalogId: 'test_catalog'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Surface(
            surfaceContext: surfaceController.contextFor(surfaceId),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.play_arrow), findsOneWidget);

    expect(find.text('Audio Description'), findsOneWidget);
  });

  group('AudioPlayer in a narrow view', () {
    for (final scale in <double>[1.0, 2.0]) {
      testWidgets('fits 320 px at ${scale}x text', (tester) async {
        final SemanticsHandle handle = await _show(tester, textScale: scale);

        expect(tester.takeException(), isNull);
        expect(find.byIcon(Icons.play_arrow), findsOneWidget);
        expect(find.bySemanticsLabel('Playback position'), findsOneWidget);
        handle.dispose();
      });
    }

    testWidgets('puts the times under the seek bar and drops the volume', (
      tester,
    ) async {
      final SemanticsHandle handle = await _show(tester);

      final Rect seekBar = tester.getRect(
        find.bySemanticsLabel('Playback position'),
      );
      expect(find.text('00:00'), findsNWidgets(2));
      for (final Element time in find.text('00:00').evaluate()) {
        final Rect rect = tester.getRect(find.byWidget(time.widget));
        expect(rect.top, greaterThanOrEqualTo(seekBar.bottom));
      }
      expect(find.bySemanticsLabel('Volume'), findsNothing);
      handle.dispose();
    });
  });

  testWidgets('AudioPlayer keeps its volume slider in a wide view', (
    tester,
  ) async {
    final SemanticsHandle handle = await _show(tester, width: 800);

    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('Volume'), findsOneWidget);
    handle.dispose();
  });
}

/// Shows a [BasicCatalogItems.audioPlayer] in a view [width] logical pixels
/// wide, with its text scaled by [textScale].
///
/// The caller disposes the returned handle.
Future<SemanticsHandle> _show(
  WidgetTester tester, {
  double width = 320,
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = Size(width, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final surfaceController = SurfaceController(
    catalogs: [
      Catalog([BasicCatalogItems.audioPlayer], catalogId: 'test_catalog'),
    ],
  );
  addTearDown(surfaceController.dispose);
  const surfaceId = 'testSurface';
  surfaceController.handleMessage(
    updateComponents(
      surfaceId: surfaceId,
      components: [
        component(
          id: 'root',
          type: 'AudioPlayer',
          properties: {
            'url': 'https://example.com/audio.mp3',
            'description': 'Audio Description',
          },
        ),
      ],
    ),
  );
  surfaceController.handleMessage(
    createSurface(surfaceId: surfaceId, catalogId: 'test_catalog'),
  );

  final SemanticsHandle handle = tester.ensureSemantics();
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery.withClampedTextScaling(
        minScaleFactor: textScale,
        maxScaleFactor: textScale,
        child: Scaffold(
          body: Surface(
            surfaceContext: surfaceController.contextFor(surfaceId),
          ),
        ),
      ),
    ),
  );
  return handle;
}
