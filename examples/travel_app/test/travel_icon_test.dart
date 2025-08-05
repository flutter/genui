import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui_client/src/catalog/travel_icon.dart';

void main() {
  group('travelIcon', () {
    testWidgets('renders correct icon', (WidgetTester tester) async {
      final data = {'icon': 'hotel'};
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return travelIcon.widgetBuilder(
                  data: data,
                  id: 'testId',
                  buildChild: (_) => const SizedBox.shrink(),
                  dispatchEvent: (event) {},
                  context: context,
                );
              },
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.hotel), findsOneWidget);
    });

    testWidgets('renders empty box for invalid icon', (
      WidgetTester tester,
    ) async {
      final data = {'icon': 'invalid_icon'};
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return travelIcon.widgetBuilder(
                  data: data,
                  id: 'testId',
                  buildChild: (_) => const SizedBox.shrink(),
                  dispatchEvent: (event) {},
                  context: context,
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
    });
  });
}
