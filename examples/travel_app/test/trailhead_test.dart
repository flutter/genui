import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui_client/src/catalog/trailhead.dart';

void main() {
  group('trailheadCatalogItem', () {
    testWidgets('builds widget correctly', (WidgetTester tester) async {
      final data = {
        'topics': ['Topic A', 'Topic B'],
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return trailheadCatalogItem.widgetBuilder(
                  data: data,
                  id: 'testId',
                  buildChild: (_) => const SizedBox.shrink(),
                  dispatchActionEvent:
                      ({
                        required widgetId,
                        required eventType,
                        required value,
                      }) {},
                  dispatchChangeEvent:
                      ({
                        required widgetId,
                        required eventType,
                        required value,
                      }) {},
                  context: context,
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Topic A'), findsOneWidget);
      expect(find.text('Topic B'), findsOneWidget);
    });
  });
}
