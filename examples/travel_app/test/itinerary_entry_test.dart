// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_app/src/catalog/itinerary_entry.dart';

void main() {
  group('ItineraryEntry', () {
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
                    'title': testTitle,
                    'bodyText': testBodyText,
                    'time': '10:00 AM',
                    'type': 'activity',
                    'status': 'noBookingRequired',
                  },
                  id: 'test_id',
                  buildChild: (id) => const SizedBox.shrink(),
                  dispatchEvent: (event) {},
                  context: context,
                  values: {},
                );
              },
            ),
          ),
        ),
      );

      expect(find.text(testTitle), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(MarkdownBody),
          matching: find.byType(RichText),
        ),
        findsOneWidget,
      );
    });
  });
}
