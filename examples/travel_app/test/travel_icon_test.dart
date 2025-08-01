import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui_client/src/catalog/travel_icon.dart';

void main() {
  group('TravelIcon Widget', () {
    testWidgets('travelIcon builds an Icon widget with the correct icon', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return travelIcon.widgetBuilder(
                  data: {'icon': 'airport'},
                  id: 'test_icon',
                  buildChild: (childId) => const SizedBox(),
                  dispatchEvent:
                      ({required widgetId, required eventType, value}) {},
                  context: context,
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(Icon), findsOneWidget);
      expect(find.byIcon(Icons.flight), findsOneWidget);
    });

    testWidgets('travelIcon builds a SizedBox when the icon is not found', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return travelIcon.widgetBuilder(
                  data: {'icon': 'invalid_icon'},
                  id: 'test_icon',
                  buildChild: (childId) => const SizedBox(),
                  dispatchEvent:
                      ({required widgetId, required eventType, value}) {},
                  context: context,
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);
    });
  });
}
