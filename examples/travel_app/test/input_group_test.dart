// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_app/src/catalog/input_group.dart';

void main() {
  group('inputGroup', () {
    testWidgets(
      'renders children and dispatches submit event on button press',
      (WidgetTester tester) async {
        final data = {
          'submitLabel': 'Submit',
          'children': ['child1', 'child2'],
        };
        UiEvent? dispatchedEvent;

        Widget buildChild(String id) => Text(id);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return inputGroup.widgetBuilder(
                    data: data,
                    id: 'testId',
                    buildChild: buildChild,
                    dispatchEvent: (event) {
                      dispatchedEvent = event;
                    },
                    context: context,
                    values: {},
                  );
                },
              ),
            ),
          ),
        );

        // Verify that children and the submit button are rendered.
        expect(find.text('child1'), findsOneWidget);
        expect(find.text('child2'), findsOneWidget);
        final button = find.widgetWithText(ElevatedButton, 'Submit');
        expect(button, findsOneWidget);

        // Verify that the submit event is dispatched on tap.
        await tester.tap(button);
        expect(dispatchedEvent, isA<UiActionEvent>());
        expect(dispatchedEvent?.eventType, 'submit');
        expect((dispatchedEvent as UiActionEvent).widgetId, 'testId');
      },
    );

    testWidgets('renders correctly with no children', (
      WidgetTester tester,
    ) async {
      final data = {'submitLabel': 'Submit', 'children': <String>[]};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return inputGroup.widgetBuilder(
                  data: data,
                  id: 'testId',
                  buildChild: (_) => const SizedBox.shrink(),
                  dispatchEvent: (UiEvent _) {},
                  context: context,
                  values: {},
                );
              },
            ),
          ),
        ),
      );

      // Verify that the submit button is rendered, but no children are.
      expect(find.byType(Text), findsOneWidget); // The button label
      expect(find.widgetWithText(ElevatedButton, 'Submit'), findsOneWidget);
    });
  });
}
