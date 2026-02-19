// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
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

    final Map<String, Object> testData = {
      'title': 'My Awesome Trip',
      'subheading': 'A 3-day adventure',
      'imageChildId': 'image1',
      'days': [
        {
          'title': 'Day 1',
          'subtitle': 'Arrival and Exploration',
          'description': 'Welcome to the city!',
          'imageChildId': 'image2',
          'entries': [
            {
              'title': 'Choose your hotel',
              'bodyText': 'Select a hotel for your stay.',
              'time': '3:00 PM',
              'type': 'accommodation',
              'status': 'choiceRequired',
              'choiceRequiredAction': {
                'event': {'name': 'testAction', 'context': <String, Object?>{}},
              },
            },
          ],
        },
      ],
    };

    // 2. Pump the widget using Builder to get a valid context
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            final Widget itineraryWidget = itinerary.widgetBuilder(
              CatalogItemContext(
                getCatalogItem: (type) => null,
                data: testData,
                id: 'itinerary1',
                type: 'Itinerary',
                buildChild: (data, [_]) => SizedBox(key: Key(data)),
                dispatchEvent: mockDispatchEvent,
                buildContext: context,
                dataContext: DataContext(InMemoryDataModel(), DataPath.root),
                getComponent: (String componentId) =>
                    throw UnimplementedError(),
                surfaceId: 'surface1',
                reportError: (e, s) {},
              ),
            );
            return Scaffold(body: Center(child: itineraryWidget));
          },
        ),
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
    // Find button by text "Choose" inside FilledButton
    await tester.tap(find.widgetWithText(FilledButton, 'Choose'));
    await tester.pumpAndSettle();

    // 7. Verify action dispatch
    expect(capturedEvent, isNotNull);
    expect(capturedEvent!.name, 'testAction');
    expect(capturedEvent!.sourceComponentId, 'itinerary1');
  });
}
