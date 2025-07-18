import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui_client/src/dynamic_ui.dart';

void main() {
  group('DynamicUi', () {
    late StreamController<Map<String, Object?>> updateController;

    setUp(() {
      updateController = StreamController<Map<String, Object?>>.broadcast();
    });

    tearDown(() {
      updateController.close();
    });

    testWidgets('builds a simple Text widget', (WidgetTester tester) async {
      final definition = {
        'id': 'text1',
        'type': 'Text',
        'properties': {'data': 'Hello, World!'},
      };

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DynamicUi(
            definition: definition,
            updateStream: updateController.stream,
            onEvent: (_) {},
          ),
        ),
      ));

      expect(find.text('Hello, World!'), findsOneWidget);
    });

    testWidgets('builds a Column with children', (WidgetTester tester) async {
      final definition = {
        'id': 'col1',
        'type': 'Column',
        'properties': {
          'children': [
            {
              'id': 'text1',
              'type': 'Text',
              'properties': {'data': 'First'},
            },
            {
              'id': 'text2',
              'type': 'Text',
              'properties': {'data': 'Second'},
            },
          ]
        },
      };

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DynamicUi(
            definition: definition,
            updateStream: updateController.stream,
            onEvent: (_) {},
          ),
        ),
      ));

      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
      final column = tester.widget<Column>(find.byType(Column));
      expect(column.children.length, 2);
    });

    testWidgets('updates a widget via the updateStream',
        (WidgetTester tester) async {
      final definition = {
        'id': 'text1',
        'type': 'Text',
        'properties': {'data': 'Initial Text'},
      };

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DynamicUi(
            definition: definition,
            updateStream: updateController.stream,
            onEvent: (_) {},
          ),
        ),
      ));

      expect(find.text('Initial Text'), findsOneWidget);

      // Send an update
      updateController.add({
        'widgetId': 'text1',
        'properties': {'data': 'Updated Text'},
      });
      await tester.pump();

      expect(find.text('Initial Text'), findsNothing);
      expect(find.text('Updated Text'), findsOneWidget);
    });

    testWidgets('sends an event on button tap', (WidgetTester tester) async {
      Map<String, Object?>? capturedEvent;
      final definition = {
        'id': 'button1',
        'type': 'ElevatedButton',
        'properties': {
          'child': {
            'id': 'button_text',
            'type': 'Text',
            'properties': {'data': 'Tap Me'},
          }
        },
      };

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DynamicUi(
            definition: definition,
            updateStream: updateController.stream,
            onEvent: (event) {
              capturedEvent = event;
            },
          ),
        ),
      ));

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(capturedEvent, isNotNull);
      expect(capturedEvent!['widgetId'], 'button1');
      expect(capturedEvent!['eventType'], 'onTap');
    });

    testWidgets('handles TextField input', (WidgetTester tester) async {
      Map<String, Object?>? capturedEvent;
      final definition = {
        'id': 'field1',
        'type': 'TextField',
        'properties': {'value': 'Initial'},
      };

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DynamicUi(
            definition: definition,
            updateStream: updateController.stream,
            onEvent: (event) {
              capturedEvent = event;
            },
          ),
        ),
      ));

      expect(find.text('Initial'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'New Value');
      await tester.pump();

      expect(capturedEvent, isNotNull);
      expect(capturedEvent!['widgetId'], 'field1');
      expect(capturedEvent!['eventType'], 'onChanged');
      expect(capturedEvent!['value'], 'New Value');
    });
  });
}
