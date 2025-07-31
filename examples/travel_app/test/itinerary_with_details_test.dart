import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:network_image_mock/network_image_mock.dart';
import '../lib/src/catalog/itinerary_with_details.dart';

void main() {
  group('ItineraryWithDetails', () {
    testWidgets('renders card with title, subheading, and thumbnail',
        (WidgetTester tester) async {
      await mockNetworkImagesFor(() async {
        final catalogItem = itineraryWithDetails;
        final data = {
          'title': 'Test Title',
          'subheading': 'Test Subheading',
          'thumbnailUrl': 'https://example.com/thumbnail.jpg',
          'child': 'child_widget_id',
        };

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return catalogItem.widgetBuilder!(
                    data: data,
                    id: 'test_itinerary_card',
                    buildChild: (id) => const Text('Child Content'),
                    dispatchEvent: ({widgetId = '', eventType = '', value}) {},
                    context: context,
                  );
                },
              ),
            ),
          ),
        );

        expect(find.text('Test Title'), findsOneWidget);
        expect(find.text('Test Subheading'), findsOneWidget);
        expect(find.byType(Image), findsOneWidget);
      });
    });

    testWidgets('opens modal bottom sheet on tap', (WidgetTester tester) async {
      await mockNetworkImagesFor(() async {
        final catalogItem = itineraryWithDetails;
        final data = {
          'title': 'Modal Title',
          'subheading': 'Modal Subheading',
          'thumbnailUrl': 'https://example.com/modal_thumbnail.jpg',
          'child': 'modal_child_widget_id',
        };

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return catalogItem.widgetBuilder!(
                    data: data,
                    id: 'test_itinerary_modal',
                    buildChild: (id) => const Text('Modal Child Content'),
                    dispatchEvent: ({widgetId = '', eventType = '', value}) {},
                    context: context,
                  );
                },
              ),
            ),
          ),
        );

        // Tap the card to open the modal
        await tester.tap(find.byType(Card));
        await tester.pumpAndSettle();

        // Verify modal content is displayed
        expect(find.byType(Scaffold),
            findsNWidgets(2)); // Main Scaffold + Modal Scaffold
        expect(
            find.descendant(
                of: find.byType(Scaffold).last,
                matching: find.text('Modal Title')),
            findsOneWidget);
        expect(
            find.descendant(
                of: find.byType(Scaffold).last,
                matching: find.text('Modal Child Content')),
            findsOneWidget);
        expect(
            find.byType(Image), findsNWidgets(2)); // One in card, one in modal

        // Tap close button
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Verify modal is dismissed
        expect(find.byType(Scaffold),
            findsOneWidget); // Only the main Scaffold should remain
        expect(find.text('Modal Child Content'),
            findsNothing); // The modal content should be gone
      });
    });
  });
}
