// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:travel_app/src/catalog/itinerary_day.dart';

void main() {
  group('ItineraryDay', () {
    testWidgets('renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: itineraryDay.widgetBuilder(
                    data: {
                      'title': {'literalString': 'Day 1'},
                      'subtitle': {'literalString': 'Arrival in Tokyo'},
                      'description': {
                        'literalString': 'A day of exploring the city.',
                      },
                      'imageChildId': 'tokyo_image',
                      'children': <String>[],
                    },
                    id: 'test',
                    buildChild: (_) => const Placeholder(),
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

      expect(find.text('Day 1'), findsOneWidget);
      expect(find.text('Arrival in Tokyo'), findsOneWidget);
      expect(find.text('A day of exploring the city.'), findsOneWidget);
    });

    testWidgets('renders correctly with markdown', (WidgetTester tester) async {
      await mockNetworkImagesFor(() async {
        const testTitle = 'Test Title';
        const testSubtitle = 'Test Subtitle';
        const testDescription = 'Test **Description**';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return itineraryDay.widgetBuilder(
                    data: {
                      'title': {'literalString': testTitle},
                      'subtitle': {'literalString': testSubtitle},
                      'description': {'literalString': testDescription},
                      'imageChildId': 'image_child_id',
                      'children': <String>[],
                    },
                    id: 'test_id',
                    buildChild: (id) {
                      if (id == 'image_child_id') {
                        return Image.network(
                          'https://example.com/thumbnail.jpg',
                        );
                      }
                      return const SizedBox.shrink();
                    },
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
        expect(find.text(testSubtitle), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(GptMarkdown),
            matching: find.byType(RichText),
          ),
          findsOneWidget,
        );
        expect(find.byType(Image), findsOneWidget);
      });
    });
  });
}
