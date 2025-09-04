// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:travel_app/src/catalog/itinerary_day.dart';

void main() {
  group('ItineraryDay', () {
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
                      'title': testTitle,
                      'subtitle': testSubtitle,
                      'description': testDescription,
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
                    values: {},
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
            of: find.byType(MarkdownBody),
            matching: find.byType(RichText),
          ),
          findsOneWidget,
        );
        expect(find.byType(Image), findsOneWidget);
      });
    });
  });
}
