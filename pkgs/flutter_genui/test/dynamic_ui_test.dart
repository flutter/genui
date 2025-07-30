import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final testCatalog = Catalog([elevatedButtonCatalogItem, text]);

  testWidgets('DynamicUi builds a widget from a definition', (
    WidgetTester tester,
  ) async {
    final definition = UiDefinition.fromMap({
      'surfaceId': 'testSurface',
      'root': 'root',
      'widgets': [
        {
          'id': 'root',
          'widget': {
            'elevated_button': {'child': 'text'},
          },
        },
        {
          'id': 'text',
          'widget': {
            'text': {'text': 'Hello'},
          },
        },
      ],
    });

    await tester.pumpWidget(
      MaterialApp(
        home: DynamicUi(
          catalog: testCatalog,
          surfaceId: 'testSurface',
          definition: definition,
          onEvent: (event) {},
        ),
      ),
    );

    expect(find.text('Hello'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('DynamicUi handles events', (WidgetTester tester) async {
    Map<String, Object?>? event;

    final definition = UiDefinition.fromMap({
      'surfaceId': 'testSurface',
      'root': 'root',
      'widgets': [
        {
          'id': 'root',
          'widget': {
            'elevated_button': {'child': 'text'},
          },
        },
        {
          'id': 'text',
          'widget': {
            'text': {'text': 'Hello'},
          },
        },
      ],
    });

    await tester.pumpWidget(
      MaterialApp(
        home: DynamicUi(
          catalog: testCatalog,
          surfaceId: 'testSurface',
          definition: definition,
          onEvent: (e) {
            event = e;
          },
        ),
      ),
    );

    await tester.tap(find.byType(ElevatedButton));

    expect(event, isNotNull);
    expect(event!['surfaceId'], 'testSurface');
    expect(event!['widgetId'], 'root');
    expect(event!['eventType'], 'onTap');
  });
}
