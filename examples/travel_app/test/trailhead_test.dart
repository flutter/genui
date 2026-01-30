// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:travel_app/src/catalog/trailhead.dart';

void main() {
  group('trailhead', () {
    testWidgets('builds widget correctly and handles tap', (
      WidgetTester tester,
    ) async {
      final Map<String, Object> data = {
        'topics': ['Topic A', 'Topic B'],
        'action': {
          'event': {'name': 'selectTopic'},
        },
      };
      UiEvent? dispatchedEvent;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return trailhead.widgetBuilder(
                  CatalogItemContext(
                    data: data,
                    id: 'testId',
                    type: 'Trailhead',
                    buildChild: (_, [_]) => const SizedBox.shrink(),
                    dispatchEvent: (event) {
                      dispatchedEvent = event;
                    },
                    buildContext: context,
                    dataContext: DataContext(DataModel(), '/'),
                    getComponent: (String componentId) => null,
                    surfaceId: 'surface1',
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Topic A'), findsOneWidget);
      expect(find.text('Topic B'), findsOneWidget);

      await tester.tap(find.text('Topic A'));
      await tester.pump();

      expect(dispatchedEvent, isA<UserActionEvent>());
      final actionEvent = dispatchedEvent as UserActionEvent;
      expect(actionEvent.sourceComponentId, 'testId');
      expect(actionEvent.name, 'selectTopic');
      expect(actionEvent.context, {'topic': 'Topic A'});
    });

    testWidgets('builds widget correctly with no topics', (
      WidgetTester tester,
    ) async {
      final Map<String, Object> data = {
        'topics': <Map<String, String>>[],
        'action': {
          'event': {'name': 'selectTopic'},
        },
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return trailhead.widgetBuilder(
                  CatalogItemContext(
                    data: data,
                    id: 'testId',
                    type: 'Trailhead',
                    buildChild: (_, [_]) => const SizedBox.shrink(),
                    dispatchEvent: (event) {},
                    buildContext: context,
                    dataContext: DataContext(DataModel(), '/'),
                    getComponent: (String componentId) => null,
                    surfaceId: 'surface1',
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(InputChip), findsNothing);
    });
  });
}
