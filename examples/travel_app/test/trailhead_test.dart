import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui_client/src/catalog/trailhead.dart';

void main() {
  group('Trailhead', () {
    testWidgets('renders trailhead chips correctly', (
      WidgetTester tester,
    ) async {
      // Mock dispatchEvent function
      void mockDispatchEvent({
        required String widgetId,
        required String eventType,
        Object? value,
      }) {}

      // Create a CatalogItem instance with test data
      final catalogItem = trailheadCatalogItem;
      final data = {
        'topics': ['Topic 1', 'Topic 2', 'Topic 3'],
      };

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return catalogItem.widgetBuilder(
                  data: data,
                  id: 'test_trailhead',
                  buildChild: (id) => Container(), // Not used in this widget
                  dispatchEvent: mockDispatchEvent,
                  context: context,
                );
              },
            ),
          ),
        ),
      );

      // Verify that the chips are displayed
      expect(find.text('Topic 1'), findsOneWidget);
      expect(find.text('Topic 2'), findsOneWidget);
      expect(find.text('Topic 3'), findsOneWidget);
    });

    testWidgets('dispatchEvent is called on chip tap', (
      WidgetTester tester,
    ) async {
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
      final catalogItem = trailheadCatalogItem;
      final data = {
        'topics': ['Tappable Topic'],
      };

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return catalogItem.widgetBuilder(
                  data: data,
                  id: 'test_trailhead_tap',
                  buildChild: (id) => Container(), // Not used in this widget
                  dispatchEvent: mockDispatchEvent,
                  context: context,
                );
              },
            ),
          ),
        ),
      );

      // Tap on the chip
      await tester.tap(find.text('Tappable Topic'));
      await tester.pumpAndSettle();

      // Verify that dispatchEvent was called with the correct arguments
      expect(dispatchedWidgetId, 'test_trailhead_tap');
      expect(dispatchedEventType, 'trailheadTopicSelected');
      expect(dispatchedValue, 'Tappable Topic');
    });
  });
}
