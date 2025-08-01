import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui_client/src/catalog/itinerary_item.dart';
import 'package:network_image_mock/network_image_mock.dart';

void main() {
  group('ItineraryItem', () {
    testWidgets('renders title and description', (WidgetTester tester) async {
      await mockNetworkImagesFor(() async {
        const testTitle = 'Test Title';
        const testDescription = 'Test Description';

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return itineraryItem.widgetBuilder(
                  data: {
                    'title': testTitle,
                    'subtitle': 'Test Subtitle',
                    'imageChild': 'image_child_id',
                    'detailText': testDescription,
                  },
                  id: 'test_id',
                  buildChild: (id) => Image.network(
                    'https://example.com/thumbnail.jpg',
                  ), // Mock buildChild
                  dispatchEvent:
                      ({
                        required widgetId,
                        required eventType,
                        required value,
                      }) {}, // Mock dispatchEvent
                  context: context,
                );
              },
            ),
          ),
        );

        expect(find.text(testTitle), findsOneWidget);
        expect(find.text(testDescription), findsOneWidget);
      });
    });
  });
}
