import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui_client/src/dynamic_ui.dart';

void main() {
  group('DynamicUi', () {
    testWidgets('builds a simple Text widget', (WidgetTester tester) async {
      final definition = {
        'root': 'text1',
        'widgets': [
          {
            'id': 'text1',
            'type': 'Text',
            'props': {
              'data': 'Hello, World!',
              'fontSize': 18.0,
              'fontWeight': 'bold'
            },
          }
        ],
      };

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DynamicUi(
            surfaceId: 'test-surface',
            definition: definition,
            onEvent: (_) {},
          ),
        ),
      ));

      expect(find.text('Hello, World!'), findsOneWidget);
      final text = tester.widget<Text>(find.text('Hello, World!'));
      expect(text.style?.fontSize, 18.0);
      expect(text.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('builds a Column with children', (WidgetTester tester) async {
      final definition = {
        'root': 'col1',
        'widgets': [
          {
            'id': 'col1',
            'type': 'Column',
            'props': {
              'children': ['text1', 'text2'],
              'mainAxisAlignment': 'center',
              'crossAxisAlignment': 'end',
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
            surfaceId: 'test-surface',
            definition: definition,
            onEvent: (_) {},
          ),
        ),
      ));

      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
      final column = tester.widget<Column>(find.byType(Column));
      expect(column.children.length, 2);
      expect(column.mainAxisAlignment, MainAxisAlignment.center);
      expect(column.crossAxisAlignment, CrossAxisAlignment.end);
    });

    testWidgets('builds a Row with children', (WidgetTester tester) async {
      final definition = {
        'root': 'row1',
        'widgets': [
          {
            'id': 'row1',
            'type': 'Row',
            'props': {
              'children': ['text1', 'text2'],
              'mainAxisAlignment': 'spaceBetween',
              'crossAxisAlignment': 'start',
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
            surfaceId: 'test-surface',
            definition: definition,
            onEvent: (_) {},
          ),
        ),
      ));

      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
      final row = tester.widget<Row>(find.byType(Row));
      expect(row.children.length, 2);
      expect(row.mainAxisAlignment, MainAxisAlignment.spaceBetween);
      expect(row.crossAxisAlignment, CrossAxisAlignment.start);
    });

    testWidgets('sends an event on button tap', (WidgetTester tester) async {
      Map<String, Object?>? capturedEvent;
      final definition = {
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
            surfaceId: 'test-surface',
            definition: definition,
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
        'root': 'field1',
        'widgets': [
          {
            'id': 'field1',
            'type': 'TextField',
            'props': {
              'value': 'Initial',
              'hintText': 'Enter text',
              'obscureText': true
            },
          }
        ],
      };

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DynamicUi(
            surfaceId: 'test-surface',
            definition: definition,
            onEvent: (event) {
              capturedEvent = event;
            },
          ),
        ),
      ));

      final textFieldFinder = find.byType(TextField);
      final textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.controller!.text, 'Initial');
      expect(textField.decoration!.hintText, 'Enter text');
      expect(textField.obscureText, isTrue);

      await tester.enterText(textFieldFinder, 'New Value');
      await tester.pump();

      expect(capturedEvent, isNotNull);
      expect(capturedEvent!['widgetId'], 'field1');
      expect(capturedEvent!['eventType'], 'onChanged');
      expect(capturedEvent!['value'], 'New Value');
    });

    testWidgets('builds a Checkbox widget', (WidgetTester tester) async {
      Map<String, Object?>? capturedEvent;
      final definition = {
        'root': 'check1',
        'widgets': [
          {
            'id': 'check1',
            'type': 'Checkbox',
            'props': {'value': true, 'label': 'A checkbox'},
          }
        ],
      };

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DynamicUi(
            surfaceId: 'test-surface',
            definition: definition,
            onEvent: (event) {
              capturedEvent = event;
            },
          ),
        ),
      ));

      final checkboxFinder = find.byType(CheckboxListTile);
      expect(checkboxFinder, findsOneWidget);
      final checkbox = tester.widget<CheckboxListTile>(checkboxFinder);
      expect(checkbox.value, isTrue);
      expect(find.text('A checkbox'), findsOneWidget);

      await tester.tap(checkboxFinder);
      await tester.pump();

      expect(capturedEvent, isNotNull);
      expect(capturedEvent!['widgetId'], 'check1');
      expect(capturedEvent!['eventType'], 'onChanged');
      expect(capturedEvent!['value'], isFalse);
    });

    testWidgets('builds a Radio widget', (WidgetTester tester) async {
      Map<String, Object?>? capturedEvent;
      final definition = {
        'root': 'radio1',
        'widgets': [
          {
            'id': 'radio1',
            'type': 'Radio',
            'props': {'value': 'A', 'groupValue': 'B', 'label': 'Option A'},
          }
        ],
      };

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DynamicUi(
            surfaceId: 'test-surface',
            definition: definition,
            onEvent: (event) {
              capturedEvent = event;
            },
          ),
        ),
      ));

      final radioFinder = find.byType(RadioListTile<Object?>);
      expect(radioFinder, findsOneWidget);
      final radio = tester.widget<RadioListTile<Object?>>(radioFinder);
      expect(radio.value, 'A');
      // ignore: deprecated_member_use
      expect(radio.groupValue, 'B');
      expect(find.text('Option A'), findsOneWidget);

      await tester.tap(radioFinder);
      await tester.pump();

      expect(capturedEvent, isNotNull);
      expect(capturedEvent!['widgetId'], 'radio1');
      expect(capturedEvent!['eventType'], 'onChanged');
      expect(capturedEvent!['value'], 'A');
    });

    testWidgets('builds a Slider widget', (WidgetTester tester) async {
      Map<String, Object?>? capturedEvent;
      final definition = {
        'root': 'slider1',
        'widgets': [
          {
            'id': 'slider1',
            'type': 'Slider',
            'props': {'value': 50.0, 'min': 0.0, 'max': 100.0, 'divisions': 10},
          }
        ],
      };

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DynamicUi(
            surfaceId: 'test-surface',
            definition: definition,
            onEvent: (event) {
              capturedEvent = event;
            },
          ),
        ),
      ));

      final sliderFinder = find.byType(Slider);
      expect(sliderFinder, findsOneWidget);
      final slider = tester.widget<Slider>(sliderFinder);
      expect(slider.value, 50.0);
      expect(slider.min, 0.0);
      expect(slider.max, 100.0);
      expect(slider.divisions, 10);

      // This is how you drag a slider.
      final center = tester.getCenter(sliderFinder);
      final target = center.translate(100, 0);
      final gesture = await tester.startGesture(center);
      await gesture.moveTo(target);
      await gesture.up();
      await tester.pump();

      expect(capturedEvent, isNotNull);
      expect(capturedEvent!['widgetId'], 'slider1');
      expect(capturedEvent!['eventType'], 'onChanged');
      // The exact value depends on the gesture, so we just check the type.
      expect(capturedEvent!['value'], isA<double>());
    });

    testWidgets('builds an Align widget', (WidgetTester tester) async {
      final definition = {
        'root': 'align1',
        'widgets': [
          {
            'id': 'align1',
            'type': 'Align',
            'props': {
              'alignment': 'topRight',
              'child': 'text1',
            },
          },
          {
            'id': 'text1',
            'type': 'Text',
            'props': {'data': 'Aligned'},
          }
        ],
      };

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DynamicUi(
            surfaceId: 'test-surface',
            definition: definition,
            onEvent: (_) {},
          ),
        ),
      ));

      final align = tester.widget<Align>(find.byType(Align));
      expect(align.alignment, Alignment.topRight);
      expect(find.text('Aligned'), findsOneWidget);
    });

    testWidgets('builds a Padding widget', (WidgetTester tester) async {
      final definition = {
        'root': 'padding1',
        'widgets': [
          {
            'id': 'padding1',
            'type': 'Padding',
            'props': {
              'padding': {
                'left': 10.0,
                'top': 20.0,
                'right': 30.0,
                'bottom': 40.0
              },
              'child': 'text1',
            },
          },
          {
            'id': 'text1',
            'type': 'Text',
            'props': {'data': 'Padded'},
          }
        ],
      };

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DynamicUi(
            surfaceId: 'test-surface',
            definition: definition,
            onEvent: (_) {},
          ),
        ),
      ));

      final padding = tester.widget<Padding>(find.byType(Padding));
      expect(padding.padding, const EdgeInsets.fromLTRB(10, 20, 30, 40));
      expect(find.text('Padded'), findsOneWidget);
    });
  });
}
