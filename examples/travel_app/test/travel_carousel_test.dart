import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:genui_client/src/catalog/travel_carousel.dart';
import 'package:network_image_mock/network_image_mock.dart';

void main() {
  group('TravelCarousel', () {
    testWidgets('renders carousel items correctly', (WidgetTester tester) async {
      await mockNetworkImagesFor(() async {
        // Mock dispatchEvent function
        void mockDispatchEvent({
          required String widgetId,
          required String eventType,
          Object? value,
        }) {}

        // Create a CatalogItem instance with test data
        final catalogItem = travelCarousel;
        final data = {
          'items': [
            {'title': 'Item 1', 'photoUrl': 'https://example.com/photo1.jpg'},
            {'title': 'Item 2', 'photoUrl': 'https://example.com/photo2.jpg'},
          ],
        };

        // Build the widget
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return catalogItem.widgetBuilder!(
                    data: data,
                    id: 'test_travel_carousel',
                    buildChild: (id) => Container(), // Not used in this widget
                    dispatchEvent: mockDispatchEvent,
                    context: context,
                  );
                },
              ),
            ),
          ),
        );

        // Verify that the titles are displayed
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 2'), findsOneWidget);

        // Verify that the images are present (by type, as network images are hard to test directly)
        expect(find.byType(Image), findsNWidgets(2));
      });
    });

    testWidgets('dispatchEvent is called on item tap', (WidgetTester tester) async {
      await mockNetworkImagesFor(() async {
        // Variables to capture dispatched event data
        String? dispatchedWidgetId;
        String? dispatchedEventType;
        Object? dispatchedValue;

        // Mock dispatchEvent function
        void mockDispatchEvent({
          required String widgetId,
          required String eventType,
          Object? value,
        }) {
          dispatchedWidgetId = widgetId;
          dispatchedEventType = eventType;
          dispatchedValue = value;
        }

        // Create a CatalogItem instance with test data
        final catalogItem = travelCarousel;
        final data = {
          'items': [
            {'title': 'Tappable Item', 'photoUrl': 'https://example.com/tappable.jpg'},
          ],
        };

        // Build the widget
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return catalogItem.widgetBuilder!(
                    data: data,
                    id: 'test_travel_carousel_tap',
                    buildChild: (id) => Container(),
                    dispatchEvent: mockDispatchEvent,
                    context: context,
                  );
                },
              ),
            ),
          ),
        );

        // Tap on the item
        await tester.tap(find.text('Tappable Item'));
        await tester.pumpAndSettle();

        // Verify that dispatchEvent was called with the correct arguments
        expect(dispatchedWidgetId, 'test_travel_carousel_tap');
        expect(dispatchedEventType, 'itemSelected');
        expect(dispatchedValue, 'Tappable Item');
      });
    });
  });
}
