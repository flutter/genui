// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Core Widgets', () {
    final testCatalog = Catalog([
      elevatedButtonCatalogItem,
      text,
      checkboxGroup,
      columnCatalogItem,
      radioGroup,
      textField,
    ]);

    Future<void> pumpWidgetWithDefinition(
      WidgetTester tester,
      Map<String, Object?> definition,
      void Function(Map<String, Object?>) onEvent,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicUi(
              catalog: testCatalog,
              surfaceId: 'testSurface',
              definition: UiDefinition.fromMap(definition),
              onEvent: onEvent,
            ),
          ),
        ),
      );
    }

    testWidgets('ElevatedButton renders and handles taps', (
      WidgetTester tester,
    ) async {
      Map<String, Object?>? event;
      final definition = {
        'surfaceId': 'testSurface',
        'root': 'button',
        'widgets': [
          {
            'id': 'button',
            'widget': {
              'elevated_button': {'child': 'text'},
            },
          },
          {
            'id': 'text',
            'widget': {
              'text': {'text': 'Click Me'},
            },
          },
        ],
      };

      await pumpWidgetWithDefinition(tester, definition, (e) => event = e);

      expect(find.text('Click Me'), findsOneWidget);
      await tester.tap(find.byType(ElevatedButton));

      expect(event, isNotNull);
      expect(event!['widgetId'], 'button');
      expect(event!['eventType'], 'onTap');
    });

    testWidgets('CheckboxGroup renders and handles changes', (
      WidgetTester tester,
    ) async {
      Map<String, Object?>? event;
      final definition = {
        'surfaceId': 'testSurface',
        'root': 'checkboxes',
        'widgets': [
          {
            'id': 'checkboxes',
            'widget': {
              'checkbox_group': {
                'values': [true, false],
                'labels': ['A', 'B'],
              },
            },
          },
        ],
      };

      await pumpWidgetWithDefinition(tester, definition, (e) => event = e);

      expect(find.byType(CheckboxListTile), findsNWidgets(2));
      final firstCheckbox = tester.widget<CheckboxListTile>(
        find.byType(CheckboxListTile).first,
      );
      expect(firstCheckbox.value, isTrue);
      await tester.tap(find.text('B'));

      expect(event, isNotNull);
      expect(event!['widgetId'], 'checkboxes');
      expect(event!['eventType'], 'onChanged');
      expect(event!['value'], [true, true]);
    });

    testWidgets('Column renders children', (WidgetTester tester) async {
      final definition = {
        'surfaceId': 'testSurface',
        'root': 'col',
        'widgets': [
          {
            'id': 'col',
            'widget': {
              'Column': {
                'children': ['text1', 'text2'],
                'spacing': 16.0,
              },
            },
          },
          {
            'id': 'text1',
            'widget': {
              'text': {'text': 'First'},
            },
          },
          {
            'id': 'text2',
            'widget': {
              'text': {'text': 'Second'},
            },
          },
        ],
      };

      await pumpWidgetWithDefinition(tester, definition, (e) {});

      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
      final column = tester.widget<Column>(find.byType(Column));
      expect(column.children.length, 3); // 2 children + 1 SizedBox
      expect(
        column.children[1],
        isA<SizedBox>().having((s) => s.height, 'height', 16.0),
      );
    });

    testWidgets('RadioGroup renders and handles changes', (
      WidgetTester tester,
    ) async {
      Map<String, Object?>? event;
      final definition = {
        'surfaceId': 'testSurface',
        'root': 'radios',
        'widgets': [
          {
            'id': 'radios',
            'widget': {
              'radio_group': {
                'groupValue': 'A',
                'labels': ['A', 'B'],
              },
            },
          },
        ],
      };

      await pumpWidgetWithDefinition(tester, definition, (e) => event = e);

      expect(find.byType(RadioListTile<String>), findsNWidgets(2));
      await tester.tap(find.text('B'));

      expect(event, isNotNull);
      expect(event!['widgetId'], 'radios');
      expect(event!['eventType'], 'onChanged');
      expect(event!['value'], 'B');
    });

    testWidgets('TextField renders and handles changes/submissions', (
      WidgetTester tester,
    ) async {
      Map<String, Object?>? event;
      final definition = {
        'surfaceId': 'testSurface',
        'root': 'field',
        'widgets': [
          {
            'id': 'field',
            'widget': {
              'text_field': {'value': 'initial', 'hintText': 'hint'},
            },
          },
        ],
      };

      await pumpWidgetWithDefinition(tester, definition, (e) => event = e);

      final textFieldFinder = find.byType(TextField);
      expect(find.widgetWithText(TextField, 'initial'), findsOneWidget);
      final textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.decoration?.hintText, 'hint');

      // Test onChanged
      await tester.enterText(textFieldFinder, 'new value');
      expect(event, isNotNull);
      expect(event!['widgetId'], 'field');
      expect(event!['eventType'], 'onChanged');
      expect(event!['value'], 'new value');

      // Test onSubmitted
      event = null;
      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(event, isNotNull);
      expect(event!['widgetId'], 'field');
      expect(event!['eventType'], 'onSubmitted');
      expect(event!['value'], 'new value');
    });
  });
}
