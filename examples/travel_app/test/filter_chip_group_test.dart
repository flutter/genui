import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui_client/src/catalog/filter_chip_group.dart';

void main() {
  group('filterChipGroup', () {
    testWidgets('builds Card with ElevatedButton', (WidgetTester tester) async {
      final data = {
        'submitLabel': 'Submit',
        'children': ['child1', 'child2'],
      };

      Widget buildChild(String id) {
        return Text(id);
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return filterChipGroup.widgetBuilder(
                  data: data,
                  id: 'testId',
                  buildChild: buildChild,
                  dispatchEvent: (UiEvent _) {},
                  context: context,
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Submit'), findsOneWidget);
      expect(find.text('child1'), findsOneWidget);
      expect(find.text('child2'), findsOneWidget);
    });

    testWidgets('dispatches submit event on button press', (
      WidgetTester tester,
    ) async {
      final data = {'submitLabel': 'Submit', 'children': <String>[]};
      String? dispatchedEventType;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return filterChipGroup.widgetBuilder(
                  data: data,
                  id: 'testId',
                  buildChild: (_) => const SizedBox.shrink(),
                  dispatchEvent: (event) {
                    dispatchedEventType = event.eventType;
                  },
                  context: context,
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      expect(dispatchedEventType, 'submit');
    });
  });
}
