// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:travel_app/src/catalog/input_group.dart';

void main() {
  group('inputGroup', () {
    testWidgets(
      'renders children and dispatches submit event on button press',
      (WidgetTester tester) async {
        final Map<String, Object> data = {
          'submitLabel': 'Submit',
          'children': ['child1', 'child2'],
          'action': {
            'event': {'name': 'submitAction'},
          },
        };
        UiEvent? dispatchedEvent;

        Widget buildChild(String id, [_]) => Text(id);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return inputGroup.widgetBuilder(
                    CatalogItemContext(
                      getCatalogItem: (type) => null,
                      data: data,
                      id: 'testId',
                      type: 'InputGroup',
                      buildChild: buildChild,
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

        // Verify that children and the submit button are rendered.
        expect(find.text('child1'), findsOneWidget);
        expect(find.text('child2'), findsOneWidget);
        final Finder button = find.widgetWithText(ElevatedButton, 'Submit');
        expect(button, findsOneWidget);

        // Verify that the submit event is dispatched on tap.
        await tester.tap(button);
        expect(dispatchedEvent, isA<UserActionEvent>());
        final actionEvent = dispatchedEvent as UserActionEvent;
        expect(actionEvent.name, 'submitAction');
        expect(actionEvent.sourceComponentId, 'testId');
      },
    );

    testWidgets('renders correctly with no children', (
      WidgetTester tester,
    ) async {
      final Map<String, Object> data = {
        'submitLabel': 'Submit',
        'children': <String>[],
        'action': {
          'event': {'name': 'submitAction'},
        },
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return inputGroup.widgetBuilder(
                  CatalogItemContext(
                    getCatalogItem: (type) => null,
                    data: data,
                    id: 'testId',
                    type: 'InputGroup',
                    buildChild: (_, [_]) => const SizedBox.shrink(),
                    dispatchEvent: (UiEvent _) {},
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

      // Verify that the submit button is rendered, but no children are.
      expect(find.byType(Text), findsOneWidget); // The button label
      expect(find.widgetWithText(ElevatedButton, 'Submit'), findsOneWidget);
    });
  });
}
