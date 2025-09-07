// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_app/src/catalog/itinerary_day.dart';

void main() {
  testWidgets('ItineraryDay golden test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: itineraryDay.widgetBuilder(
                  data: {
                    'title': 'Day 1',
                    'subtitle': 'Arrival in Tokyo',
                    'description': 'A day of exploring the city.',
                    'imageChildId': 'tokyo_image',
                    'children': <String>[],
                  },
                  id: 'test',
                  buildChild: (_) => const Placeholder(),
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

    expect(find.text('Day 1'), findsOneWidget);
    expect(find.text('Arrival in Tokyo'), findsOneWidget);
    expect(find.text('A day of exploring the city.'), findsOneWidget);
  });
}
