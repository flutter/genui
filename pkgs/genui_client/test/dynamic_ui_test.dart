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
        'task_id': 'task1',
        'root': 'text1',
        'widgets': [
          {
            'id': 'text1',
            'type': 'Text',
            'props': {'data': 'Hello, World!'},
          }
        ],
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
        'task_id': 'task1',
        'root': 'col1',
        'widgets': [
          {
            'id': 'col1',
            'type': 'Column',
            'props': {
              'children': ['text1', 'text2']
            },
          },
          {
            'id': 'text1',
            'type': 'Text',
            'props': {'data': 'First'},
          },
          {
            'id': 'text2',
            'type': 'Text',
            'props': {'data': 'Second'},
          },
        ],
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
        'task_id': 'task1',
        'root': 'text1',
        'widgets': [
          {
            'id': 'text1',
            'type': 'Text',
            'props': {'data': 'Initial Text'},
          }
        ],
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
        'props': {'data': 'Updated Text'},
      });
      await tester.pump();

      expect(find.text('Initial Text'), findsNothing);
      expect(find.text('Updated Text'), findsOneWidget);
    });

    testWidgets('sends an event on button tap', (WidgetTester tester) async {
      Map<String, Object?>? capturedEvent;
      final definition = {
        'task_id': 'task1',
        'root': 'button1',
        'widgets': [
          {
            'id': 'button1',
            'type': 'ElevatedButton',
            'props': {
              'child': 'button_text',
            },
          },
          {
            'id': 'button_text',
            'type': 'Text',
            'props': {'data': 'Tap Me'},
          }
        ],
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
        'task_id': 'task1',
        'root': 'field1',
        'widgets': [
          {
            'id': 'field1',
            'type': 'TextField',
            'props': {'value': 'Initial'},
          }
        ],
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

      final textField = find.byType(TextField);
      expect(tester.widget<TextField>(textField).controller!.text, 'Initial');

      await tester.enterText(textField, 'New Value');
      await tester.pump();

      expect(capturedEvent, isNotNull);
      expect(capturedEvent!['widgetId'], 'field1');
      expect(capturedEvent!['eventType'], 'onChanged');
      expect(capturedEvent!['value'], 'New Value');
    });
  });
}
