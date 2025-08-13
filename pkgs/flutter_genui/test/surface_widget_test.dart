// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_test/flutter_test.dart';

class TestSurfaceHost implements SurfaceHost {
  TestSurfaceHost({required this.testCatalog, required this.onEvent});

  final Catalog testCatalog;
  final void Function(Map<String, Object?>) onEvent;

  @override
  Catalog get catalog => testCatalog;

  @override
  void sendEvent(Map<String, Object?> event) {
    onEvent(event);
  }
}

void main() {
  final testCatalog = Catalog([elevatedButtonCatalogItem, text]);

  testWidgets('SurfaceWidget builds a widget from a definition', (
    WidgetTester tester,
  ) async {
    final definition = {
      'surfaceId': 'testSurface',
      'root': 'root',
      'widgets': [
        {
          'id': 'root',
          'widget': {
            'elevated_button': {'child': 'text'},
          },
        },
        {
          'id': 'text',
          'widget': {
            'text': {'text': 'Hello'},
          },
        },
      ],
    };

    await tester.pumpWidget(
      MaterialApp(
        home: SurfaceWidget(
          host: TestSurfaceHost(testCatalog: testCatalog, onEvent: (_) {}),
          response: UiResponseMessage(
            surfaceId: 'testSurface',
            definition: definition,
          ),
        ),
      ),
    );

    expect(find.text('Hello'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('SurfaceWidget handles events', (WidgetTester tester) async {
    Map<String, Object?>? event;

    final definition = {
      'surfaceId': 'testSurface',
      'root': 'root',
      'widgets': [
        {
          'id': 'root',
          'widget': {
            'elevated_button': {'child': 'text'},
          },
        },
        {
          'id': 'text',
          'widget': {
            'text': {'text': 'Hello'},
          },
        },
      ],
    };

    await tester.pumpWidget(
      MaterialApp(
        home: SurfaceWidget(
          host: TestSurfaceHost(
            testCatalog: testCatalog,
            onEvent: (e) {
              event = e;
            },
          ),
          response: UiResponseMessage(
            surfaceId: 'testSurface',
            definition: definition,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ElevatedButton));

    expect(event, isNotNull);
    expect(event!['surfaceId'], 'testSurface');
    expect(event!['widgetId'], 'root');
    expect(event!['eventType'], 'onTap');
  });
}
