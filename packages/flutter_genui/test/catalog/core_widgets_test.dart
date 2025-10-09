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
      String rootId,
      List<Component> components,
    ) async {
      message = null;
      manager?.dispose();
      manager = GenUiManager(
        catalog: testCatalog,
        configuration: const GenUiConfiguration(),
      );
      manager!.onSubmit.listen((event) => message = event);
      const surfaceId = 'testSurface';
      manager!.handleMessage(
        SurfaceUpdate(surfaceId: surfaceId, components: components),
      );
      manager!.handleMessage(
        BeginRendering(surfaceId: surfaceId, root: rootId),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GenUiSurface(host: manager!, surfaceId: surfaceId),
          ),
        ),
      );
    }

    testWidgets('ElevatedButton renders and handles taps', (
      WidgetTester tester,
    ) async {
      final components = [
        const Component(
          id: 'button',
          componentProperties: {
            'ElevatedButton': {
              'child': 'text',
              'action': {'actionName': 'testAction'},
            },
          },
        ),
        const Component(
          id: 'text',
          componentProperties: {
            'Text': {
              'text': {'literalString': 'Click Me'},
            },
          },
        ),
      ];

      await pumpWidgetWithDefinition(tester, 'button', components);

      expect(find.text('Click Me'), findsOneWidget);

      expect(message, null);
      await tester.tap(find.byType(ElevatedButton));
      expect(message, isNotNull);
    });

    testWidgets('Text renders from data model', (WidgetTester tester) async {
      final components = [
        const Component(
          id: 'text',
          componentProperties: {
            'Text': {
              'text': {'path': '/myText'},
            },
          },
        ),
      ];

      await pumpWidgetWithDefinition(tester, 'text', components);
      manager!
          .dataModelForSurface('testSurface')
          .update('/myText', 'Hello from data model');
      await tester.pumpAndSettle();

      expect(find.text('Hello from data model'), findsOneWidget);
    });

    testWidgets('CheckboxGroup renders and handles changes', (
      WidgetTester tester,
    ) async {
      final components = [
        const Component(
          id: 'checkboxes',
          componentProperties: {
            'CheckboxGroup': {
              'selectedValues': {'path': '/checkboxes'},
              'labels': ['A', 'B'],
            },
          },
        ),
      ];

      await pumpWidgetWithDefinition(tester, 'checkboxes', components);

      manager!.dataModels['testSurface']!.update('/checkboxes', ['A']);

      await tester.pumpAndSettle();

      expect(find.byType(CheckboxListTile), findsNWidgets(2));
      final firstCheckbox = tester.widget<CheckboxListTile>(
        find.byType(CheckboxListTile).first,
      );
      expect(firstCheckbox.value, isTrue);

      await tester.tap(find.text('B'));

      expect(message, null);
      expect(
        manager!.dataModels['testSurface']!.getValue<List<String>>(
          '/checkboxes',
        ),
        ['A', 'B'],
      );
    });

    testWidgets('Column renders children', (WidgetTester tester) async {
      final components = [
        const Component(
          id: 'col',
          componentProperties: {
            'Column': {
              'children': ['text1', 'text2'],
              'spacing': 16.0,
            },
          },
        ),
        const Component(
          id: 'text1',
          componentProperties: {
            'Text': {
              'text': {'literalString': 'First'},
            },
          },
        ),
        const Component(
          id: 'text2',
          componentProperties: {
            'Text': {
              'text': {'literalString': 'Second'},
            },
          },
        ),
      ];

      await pumpWidgetWithDefinition(tester, 'col', components);

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
      final components = [
        const Component(
          id: 'radios',
          componentProperties: {
            'RadioGroup': {
              'groupValue': {'path': '/radioValue'},
              'labels': ['A', 'B'],
            },
          },
        ),
      ];

      await pumpWidgetWithDefinition(tester, 'radios', components);
      manager!.dataModelForSurface('testSurface').update('/radioValue', 'A');
      await tester.pumpAndSettle();

      expect(find.byType(RadioListTile<String>), findsNWidgets(2));
      await tester.tap(find.text('B'));
      await tester.pumpAndSettle();

      expect(message, null);
      expect(
        manager!
            .dataModelForSurface('testSurface')
            .getValue<String>('/radioValue'),
        'B',
      );
    });

    testWidgets('TextField renders and handles changes/submissions', (
      WidgetTester tester,
    ) async {
      final components = [
        const Component(
          id: 'field',
          componentProperties: {
            'TextField': {
              'value': {'path': '/myValue'},
              'hintText': 'hint',
              'onSubmittedAction': {'actionName': 'submit'},
            },
          },
        ),
      ];

      await pumpWidgetWithDefinition(tester, 'field', components);
      manager!.dataModelForSurface('testSurface').update('/myValue', 'initial');
      await tester.pumpAndSettle();

      final textFieldFinder = find.byType(TextField);
      expect(find.widgetWithText(TextField, 'initial'), findsOneWidget);
      final textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.decoration?.hintText, 'hint');

      // Test onChanged
      await tester.enterText(textFieldFinder, 'new value');
      expect(
        manager!
            .dataModelForSurface('testSurface')
            .getValue<String>('/myValue'),
        'new value',
      );

      // Test onSubmitted
      expect(message, null);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(message, isNotNull);
    });
  });
}
