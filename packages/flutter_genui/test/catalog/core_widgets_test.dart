// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Core Widgets', () {
    final testCatalog = CoreCatalogItems.asCatalog();

    UserMessage? message;
    GenUiManager? manager;

    Future<void> pumpWidgetWithDefinition(
      WidgetTester tester,
      Map<String, Object?> definition,
    ) async {
      message = null;
      manager?.dispose();
      manager = GenUiManager(
        catalog: testCatalog,
        configuration: const GenUiConfiguration(),
      );
      manager!.onSubmit.listen((event) => message = event);
      manager!.addOrUpdateSurface('testSurface', definition);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GenUiSurface(host: manager!, surfaceId: 'testSurface'),
          ),
        ),
      );
    }

    testWidgets('ElevatedButton renders and handles taps', (
      WidgetTester tester,
    ) async {
      final definition = {
        'root': 'button',
        'widgets': [
          {
            'id': 'button',
            'widget': {
              'ElevatedButton': {'child': 'text'},
            },
          },
          {
            'id': 'text',
            'widget': {
              'Text': {
                'text': {'literalString': 'Click Me'},
              },
            },
          },
        ],
      };

      await pumpWidgetWithDefinition(tester, definition);

      expect(find.text('Click Me'), findsOneWidget);

      expect(message, null);
      await tester.tap(find.byType(ElevatedButton));
      expect(message, isNotNull);
    });

    testWidgets('Text renders from data model', (WidgetTester tester) async {
      final definition = {
        'root': 'text',
        'widgets': [
          {
            'id': 'text',
            'widget': {
              'Text': {
                'text': {'path': '/myText'},
              },
            },
          },
        ],
      };

      await pumpWidgetWithDefinition(tester, definition);
      manager!.dataModel.update('/myText', 'Hello from data model');
      await tester.pumpAndSettle();

      expect(find.text('Hello from data model'), findsOneWidget);
    });

    testWidgets('CheckboxGroup renders and handles changes', (
      WidgetTester tester,
    ) async {
      final definition = {
        'root': 'checkboxes',
        'widgets': [
          {
            'id': 'checkboxes',
            'widget': {
              'CheckboxGroup': {
                'selectedValues': {'path': '/checkboxes'},
                'labels': ['A', 'B'],
              },
            },
          },
        ],
      };

      await pumpWidgetWithDefinition(tester, definition);

      manager!.dataModel.update('/checkboxes', ['A']);

      await tester.pumpAndSettle();

      expect(find.byType(CheckboxListTile), findsNWidgets(2));
      final firstCheckbox = tester.widget<CheckboxListTile>(
        find.byType(CheckboxListTile).first,
      );
      expect(firstCheckbox.value, isTrue);

      await tester.tap(find.text('B'));

      expect(message, null);
      expect(manager!.dataModel.getValue<List<String>>('/checkboxes'), [
        'A',
        'B',
      ]);
    });

    testWidgets('Column renders children', (WidgetTester tester) async {
      final definition = {
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
              'Text': {
                'text': {'literalString': 'First'},
              },
            },
          },
          {
            'id': 'text2',
            'widget': {
              'Text': {
                'text': {'literalString': 'Second'},
              },
            },
          },
        ],
      };

      await pumpWidgetWithDefinition(tester, definition);

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
      final definition = {
        'root': 'radios',
        'widgets': [
          {
            'id': 'radios',
            'widget': {
              'RadioGroup': {
                'groupValue': {'path': '/radioValue'},
                'labels': ['A', 'B'],
              },
            },
          },
        ],
      };

      await pumpWidgetWithDefinition(tester, definition);
      manager!.dataModel.update('/radioValue', 'A');
      await tester.pumpAndSettle();

      expect(find.byType(RadioListTile<String>), findsNWidgets(2));
      await tester.tap(find.text('B'));
      await tester.pumpAndSettle();

      expect(message, null);
      expect(manager!.dataModel.getValue<String>('/radioValue'), 'B');
    });

    testWidgets('TextField renders and handles changes/submissions', (
      WidgetTester tester,
    ) async {
      final definition = {
        'root': 'field',
        'widgets': [
          {
            'id': 'field',
            'widget': {
              'TextField': {
                'value': {'path': '/myValue'},
                'hintText': 'hint',
              },
            },
          },
        ],
      };

      await pumpWidgetWithDefinition(tester, definition);
      manager!.dataModel.update('/myValue', 'initial');
      await tester.pumpAndSettle();

      final textFieldFinder = find.byType(TextField);
      expect(find.widgetWithText(TextField, 'initial'), findsOneWidget);
      final textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.decoration?.hintText, 'hint');

      // Test onChanged
      await tester.enterText(textFieldFinder, 'new value');
      expect(manager!.dataModel.getValue<String>('/myValue'), 'new value');

      // Test onSubmitted
      expect(message, null);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(message, isNotNull);
    });
  });
}
