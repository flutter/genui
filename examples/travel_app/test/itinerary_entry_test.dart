// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:travel_app/src/catalog/itinerary_entry.dart';

void main() {
  group('ItineraryEntry', () {
    testWidgets('renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: itineraryEntry.widgetBuilder(
                    data: {
                      'title': {'literalString': 'Arrival at HND Airport'},
                      'subtitle': {
                        'literalString': 'Tokyo International Airport',
                      },
                      'bodyText': {
                        'literalString':
                            'Arrive at Haneda Airport (HND), clear customs, '
                            'and pick up your luggage.',
                      },
                      'time': {'literalString': '3:00 PM'},
                      'type': 'transport',
                      'status': 'noBookingRequired',
                    },
                    id: 'test',
                    buildChild: (_) => const SizedBox(),
                    dispatchEvent: (_) {},
                    context: context,
                    dataContext: DataContext(DataModel(), '/'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Arrival at HND Airport'), findsOneWidget);
      expect(find.text('Tokyo International Airport'), findsOneWidget);
      expect(
        find.text(
          'Arrive at Haneda Airport (HND), clear customs, and pick up your '
          'luggage.',
        ),
        findsOneWidget,
      );
      expect(find.text('3:00 PM'), findsOneWidget);
    });

    testWidgets('renders correctly with markdown', (WidgetTester tester) async {
      const testTitle = 'Test Title';
      const testBodyText = 'Test **Body** Text';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return itineraryEntry.widgetBuilder(
                  data: {
                    'title': {'literalString': testTitle},
                    'bodyText': {'literalString': testBodyText},
                    'time': {'literalString': '10:00 AM'},
                    'type': 'activity',
                    'status': 'noBookingRequired',
                  },
                  id: 'test_id',
                  buildChild: (id) => const SizedBox.shrink(),
                  dispatchEvent: (event) {},
                  context: context,
                  dataContext: DataContext(DataModel(), '/'),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text(testTitle), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(GptMarkdown),
          matching: find.byType(RichText),
        ),
        findsOneWidget,
      );
    });
  });
}
