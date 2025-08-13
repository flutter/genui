// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:travel_app/src/catalog/itinerary_item.dart';

void main() {
  group('ItineraryItem', () {
    testWidgets('renders title, subtitle, detail text and image', (
      WidgetTester tester,
    ) async {
      await mockNetworkImagesFor(() async {
        const testTitle = 'Test Title';
        const testSubtitle = 'Test Subtitle';
        const testDetailText = 'Test Detail Text';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return itineraryItem.widgetBuilder(
                    data: {
                      'title': testTitle,
                      'subtitle': testSubtitle,
                      'imageChildId': 'image_child_id',
                      'detailText': testDetailText,
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
                    dispatchEvent: (event) {}, // Mock dispatchEvent
                    context: context,
                  );
                },
              ),
            ),
          ),
        );

        expect(find.text(testTitle), findsOneWidget);
        expect(find.text(testSubtitle), findsOneWidget);
        expect(find.text(testDetailText), findsOneWidget);
        expect(find.byType(Image), findsOneWidget);
      });
    });

    testWidgets('renders without image', (WidgetTester tester) async {
      await mockNetworkImagesFor(() async {
        const testTitle = 'Test Title';
        const testSubtitle = 'Test Subtitle';
        const testDetailText = 'Test Detail Text';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return itineraryItem.widgetBuilder(
                    data: {
                      'title': testTitle,
                      'subtitle': testSubtitle,
                      'detailText': testDetailText,
                    },
                    id: 'test_id',
                    buildChild: (id) =>
                        const SizedBox.shrink(), // Mock buildChild
                    dispatchEvent: (event) {}, // Mock dispatchEvent
                    context: context,
                  );
                },
              ),
            ),
          ),
        );

        expect(find.text(testTitle), findsOneWidget);
        expect(find.text(testSubtitle), findsOneWidget);
        expect(find.text(testDetailText), findsOneWidget);
        expect(find.byType(Image), findsNothing);
      });
    });
  });
}
