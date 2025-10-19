// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_app/src/catalog/itinerary.dart';

void main() {
  testWidgets('Itinerary widget renders, opens modal, and handles actions', (
    WidgetTester tester,
  ) async {
    // 1. Define mock data and collaborators
    UserActionEvent? capturedEvent;
    void mockDispatchEvent(UiEvent event) {
      if (event is UserActionEvent) {
        capturedEvent = event;
      }
    }

    final testData = {
      'title': {'literalString': 'My Awesome Trip'},
      'subheading': {'literalString': 'A 3-day adventure'},
      'imageChildId': 'image1',
      'days': [
        {
          'title': {'literalString': 'Day 1'},
          'subtitle': {'literalString': 'Arrival and Exploration'},
          'description': {'literalString': 'Welcome to the city!'},
          'imageChildId': 'image2',
          'entries': [
            {
              'title': {'literalString': 'Choose your hotel'},
              'bodyText': {'literalString': 'Select a hotel for your stay.'},
              'time': {'literalString': '3:00 PM'},
              'type': 'accommodation',
              'status': 'choiceRequired',
              'choiceRequiredAction': {
                'name': 'testAction',
                'context': <Object?>[],
              },
            },
          ],
        },
      ],
    };

    final itineraryWidget = itinerary.widgetBuilder(
      data: testData,
      id: 'itinerary1',
      buildChild: (id) => SizedBox(key: Key(id)),
      dispatchEvent: mockDispatchEvent,
      context: tester.element(find.byType(Container)),
      dataContext: DataContext(DataModel(), '/'),
    );

    // 2. Pump the widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: itineraryWidget)),
      ),
    );

    // 3. Verify initial rendering
    expect(find.text('My Awesome Trip'), findsOneWidget);
    expect(find.text('A 3-day adventure'), findsOneWidget);

    // 4. Simulate tap to open modal
    await tester.tap(find.byType(Card));
    await tester.pumpAndSettle(); // Wait for modal animation

    // 5. Verify modal content
    expect(find.text('Day 1'), findsOneWidget);
    expect(find.text('Arrival and Exploration'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);

    // 6. Simulate tap on the action button
    await tester.tap(find.widgetWithText(FilledButton, 'Choose'));
    await tester.pumpAndSettle();

    // 7. Verify action dispatch
    expect(capturedEvent, isNotNull);
    expect(capturedEvent!.name, 'testAction');
    expect(capturedEvent!.sourceComponentId, 'itinerary1');
  });
}
