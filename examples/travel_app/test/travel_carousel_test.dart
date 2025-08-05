import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui_client/src/catalog/travel_carousel.dart';
import 'package:network_image_mock/network_image_mock.dart';

void main() {
  group('travelCarousel', () {
    testWidgets('builds correctly', (WidgetTester tester) async {
      await mockNetworkImagesFor(() async {
        final data = {
          'items': [
            {'title': 'Item 1', 'imageChild': 'imageId1'},
            {'title': 'Item 2', 'imageChild': 'imageId2'},
          ],
        };

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
                    dispatchEvent: (event) {},
                    context: context,
                  );
                },
              ),
            ),
          ),
        );

        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 2'), findsOneWidget);
        expect(find.byType(Image), findsNWidgets(2));
      });
    });
  });
}
