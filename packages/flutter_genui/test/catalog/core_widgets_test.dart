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

    testWidgets('Button renders and handles taps', (WidgetTester tester) async {
      final components = [
        const Component(
          id: 'button',
          componentProperties: {
            'Button': {
              'child': 'text',
              'action': {'name': 'testAction'},
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

    testWidgets('Column renders children', (WidgetTester tester) async {
      final components = [
        const Component(
          id: 'col',
          componentProperties: {
            'Column': {
              'children': {
                'explicitList': ['text1', 'text2'],
              },
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
    });

    testWidgets('TextField renders and handles changes/submissions', (
      WidgetTester tester,
    ) async {
      final components = [
        const Component(
          id: 'field',
          componentProperties: {
            'TextField': {
              'text': {'path': '/myValue'},
              'label': {'literalString': 'My Label'},
              'onSubmittedAction': {'name': 'submit'},
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
      expect(textField.decoration?.labelText, 'My Label');

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
