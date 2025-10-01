// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_app/src/catalog/trailhead.dart';

void main() {
  group('trailhead', () {
    testWidgets('builds widget correctly and handles tap', (
      WidgetTester tester,
    ) async {
      final data = {
        'topics': [
          {'literalString': 'Topic A'},
          {'literalString': 'Topic B'}
        ],
      };
      UiEvent? dispatchedEvent;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return trailhead.widgetBuilder(
                  data: data,
                  id: 'testId',
                  buildChild: (_) => const SizedBox.shrink(),
                  dispatchEvent: (event) {
                    dispatchedEvent = event;
                  },
                  context: context,
                  dataContext: DataContext(DataModel(), '/'),
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

      expect(dispatchedEvent, isA<UiActionEvent>());
      final actionEvent = dispatchedEvent as UiActionEvent;
      expect(actionEvent.widgetId, 'testId');
      expect(actionEvent.eventType, 'trailheadTopicSelected');
      expect(actionEvent.value, 'Topic A');
    });

    testWidgets('builds widget correctly with no topics', (
      WidgetTester tester,
    ) async {
      final data = {'topics': <Map<String, String>>[]};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return trailhead.widgetBuilder(
                  data: data,
                  id: 'testId',
                  buildChild: (_) => const SizedBox.shrink(),
                  dispatchEvent: (event) {},
                  context: context,
                  dataContext: DataContext(DataModel(), '/'),
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