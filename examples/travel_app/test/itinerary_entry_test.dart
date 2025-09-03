// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_app/src/catalog/itinerary_entry.dart';

void main() {
  testWidgets('ItineraryEntry golden test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: itineraryEntry.widgetBuilder(
                  data: {
                    'title': 'Arrival at HND Airport',
                    'subtitle': 'Tokyo International Airport',
                    'bodyText':
                        'Arrive at Haneda Airport (HND), clear customs, and '
                        'pick up your luggage.',
                    'time': '3:00 PM',
                    'type': 'transport',
                    'status': 'noBookingRequired',
                  },
                  id: 'test',
                  buildChild: (_) => const SizedBox(),
                  dispatchEvent: (_) {},
                  context: context,
                  values: {},
                ),
              );
            },
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/itinerary_entry.png'),
    );
  });
}
