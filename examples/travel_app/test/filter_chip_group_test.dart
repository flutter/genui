import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui_client/src/catalog/filter_chip_group.dart';

void main() {
  group('FilterChipGroup', () {
    testWidgets('renders submit button and children correctly', (
      WidgetTester tester,
    ) async {
      // Mock buildChild function
      Widget mockBuildChild(String id) {
        return Text('Child: $id');
      }

      // Create a CatalogItem instance with test data
      final catalogItem = filterChipGroup;
      final data = {
        'submitLabel': 'Apply Filters',
        'children': ['chip1', 'chip2'],
      };

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return catalogItem.widgetBuilder(
                  data: data,
                  id: 'test_filter_chip_group',
                  buildChild: mockBuildChild,
                  dispatchEvent:
                      ({
                        required String widgetId,
                        required String eventType,
                        Object? value,
                      }) {},
                  context: context,
                );
              },
            ),
          ),
        ),
      );

      // Verify that the submit button is displayed with the correct label
      expect(
        find.widgetWithText(ElevatedButton, 'Apply Filters'),
        findsOneWidget,
      );

      // Verify that the children are rendered
      expect(find.text('Child: chip1'), findsOneWidget);
      expect(find.text('Child: chip2'), findsOneWidget);
    });

    testWidgets('dispatchEvent is called on submit button press', (
      WidgetTester tester,
    ) async {
      // Mock buildChild function
      Widget mockBuildChild(String id) {
        return Text('Child: $id');
      }

      // Create a CatalogItem instance with test data
      final catalogItem = filterChipGroup;
      final data = {
        'submitLabel': 'Apply Filters',
        'children': ['chip1'],
      };

      var dispatchEventCalled = false;
      String? dispatchedWidgetId;
      String? dispatchedEventType;
      dynamic dispatchedValue;

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return catalogItem.widgetBuilder(
                  data: data,
                  id: 'test_filter_chip_group',
                  buildChild: mockBuildChild,
                  dispatchEvent:
                      ({
                        required String widgetId,
                        required String eventType,
                        Object? value,
                      }) {
                        dispatchEventCalled = true;
                        dispatchedWidgetId = widgetId;
                        dispatchedEventType = eventType;
                        dispatchedValue = value;
                      },
                  context: context,
                );
              },
            ),
          ),
        ),
      );

      // Tap the submit button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Apply Filters'));
      await tester.pumpAndSettle();

      // Verify that dispatchEvent was called with the correct arguments
      expect(dispatchEventCalled, isTrue);
      expect(dispatchedWidgetId, 'test_filter_chip_group');
      expect(dispatchedEventType, 'submit');
      expect(dispatchedValue, isNull);
    });
  });
}
