// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:travel_app/src/catalog/travel_carousel.dart';

void main() {
  group('travelCarousel', () {
    testWidgets('builds correctly and handles tap', (
      WidgetTester tester,
    ) async {
      await mockNetworkImagesFor(() async {
        final data = {
          'items': [
            {
              'description': {'literalString': 'Item 1'},
              'imageChildId': 'imageId1',
              'action': {'actionName': 'selectItem'},
            },
            {
              'description': {'literalString': 'Item 2'},
              'imageChildId': 'imageId2',
              'action': {'actionName': 'selectItem'},
            },
          ],
        };
        UiEvent? dispatchedEvent;

        Widget buildChild(String id) {
          return Image.network('https://example.com/image.jpg');
        }

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return travelCarousel.widgetBuilder(
                    data: data,
                    id: 'testId',
                    buildChild: buildChild,
                    dispatchEvent: (event) {
                      dispatchedEvent = event;
                    },
                    context: context,
                    dataContext: DataContext(DataModel(), '/'),
                  );
                },
              ),
            ),
          ),
        );

        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 2'), findsOneWidget);
        expect(find.byType(Image), findsNWidgets(2));

        await tester.tap(find.text('Item 1'));
        await tester.pump();

        expect(dispatchedEvent, isA<UserActionEvent>());
        final actionEvent = dispatchedEvent as UserActionEvent;
        expect(actionEvent.sourceComponentId, 'testId');
        expect(actionEvent.actionName, 'selectItem');
        expect(actionEvent.context, {'description': 'Item 1'});
      });
    });

    testWidgets('builds correctly and handles tap with listingSelectionId', (
      WidgetTester tester,
    ) async {
      await mockNetworkImagesFor(() async {
        final data = {
          'items': [
            {
              'description': {'literalString': 'Item 1'},
              'imageChildId': 'imageId1',
              'listingSelectionId': 'listing1',
              'action': {'actionName': 'selectItem'},
            },
            {
              'description': {'literalString': 'Item 2'},
              'imageChildId': 'imageId2',
              'action': {'actionName': 'selectItem'},
            },
          ],
        };
        UiEvent? dispatchedEvent;

        Widget buildChild(String id) {
          return Image.network('https://example.com/image.jpg');
        }

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return travelCarousel.widgetBuilder(
                    data: data,
                    id: 'testId',
                    buildChild: buildChild,
                    dispatchEvent: (event) {
                      dispatchedEvent = event;
                    },
                    context: context,
                    dataContext: DataContext(DataModel(), '/'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Item 1'));
        await tester.pump();

        final actionEvent = dispatchedEvent as UserActionEvent;
        expect(actionEvent.context, {
          'description': 'Item 1',
          'listingSelectionId': 'listing1',
        });
      });
    });

    testWidgets('builds correctly with no items', (WidgetTester tester) async {
      await mockNetworkImagesFor(() async {
        final data = {'items': <Map<String, Object>>[]};

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return travelCarousel.widgetBuilder(
                    data: data,
                    id: 'testId',
                    buildChild: (_) => const SizedBox.shrink(),
                    dispatchEvent: (event) {},
                    context: context,
                    dataContext: DataContext(DataModel(), '/'),
                  );
                },
              ),
            ),
          ),
        );

        expect(find.byType(ListView), findsOneWidget);
        expect(find.byType(InkWell), findsNothing);
      });
    });
  });
}
