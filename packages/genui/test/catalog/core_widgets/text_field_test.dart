// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

import '../../test_infra/message_builders.dart';

/// Renders a single `TextField` component bound to `/value`.
Future<SurfaceController> _pumpVariant(
  WidgetTester tester, {
  required String variant,
}) async {
  final surfaceController = SurfaceController(
    catalogs: [BasicCatalogItems.asCatalog()],
  );
  addTearDown(surfaceController.dispose);
  const surfaceId = 'variantTest';

  surfaceController.handleMessage(
    updateComponents(
      surfaceId: surfaceId,
      components: [
        component(
          id: 'root',
          type: 'TextField',
          properties: {
            'label': 'Input',
            'variant': variant,
            'value': {'path': '/value'},
          },
        ),
      ],
    ),
  );
  surfaceController.handleMessage(
    createSurface(surfaceId: surfaceId, catalogId: basicCatalogId),
  );

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Surface(surfaceContext: surfaceController.contextFor(surfaceId)),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return surfaceController;
}

Object? _value(SurfaceController controller) => controller
    .contextFor('variantTest')
    .dataModel
    .getValue<Object>(DataPath('/value'));

void main() {
  testWidgets('TextField with no weight in Row defaults to weight: 1 '
      'and expands', (WidgetTester tester) async {
    final surfaceController = SurfaceController(
      catalogs: [BasicCatalogItems.asCatalog()],
    );
    addTearDown(surfaceController.dispose);
    const surfaceId = 'testSurface';
    final List<JsonMap> components = [
      component(
        id: 'root',
        type: 'Row',
        properties: {
          'children': ['text_field'],
        },
      ),
      component(
        id: 'text_field',
        type: 'TextField',
        properties: {'label': 'Input'},
        // "weight" property is left unset.
      ),
    ];

    surfaceController.handleMessage(
      updateComponents(surfaceId: surfaceId, components: components),
    );
    surfaceController.handleMessage(
      createSurface(surfaceId: surfaceId, catalogId: basicCatalogId),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Surface(
            surfaceContext: surfaceController.contextFor(surfaceId),
          ),
        ),
      ),
    );

    expect(find.byType(TextField), findsOneWidget);

    final Flexible flexible = tester.widget(
      find.ancestor(
        of: find.byType(TextField),
        matching: find.byType(Flexible),
      ),
    );
    expect(flexible.flex, 1);

    final Finder textFieldFinder = find.byType(TextField);
    final Size size = tester.getSize(textFieldFinder);
    expect(size.width, 800.0);
  });

  testWidgets('TextField in Row (with weight) expands', (
    WidgetTester tester,
  ) async {
    final surfaceController = SurfaceController(
      catalogs: [BasicCatalogItems.asCatalog()],
    );
    addTearDown(surfaceController.dispose);
    const surfaceId = 'testSurface';
    final List<JsonMap> components = [
      component(
        id: 'root',
        type: 'Row',
        properties: {
          'children': ['text_field'],
        },
      ),
      component(
        id: 'text_field',
        type: 'TextField',
        properties: {'label': 'Input', 'weight': 1},
      ),
    ];

    surfaceController.handleMessage(
      updateComponents(surfaceId: surfaceId, components: components),
    );
    surfaceController.handleMessage(
      createSurface(surfaceId: surfaceId, catalogId: basicCatalogId),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Surface(
            surfaceContext: surfaceController.contextFor(surfaceId),
          ),
        ),
      ),
    );

    expect(find.byType(TextField), findsOneWidget);

    expect(
      find.ancestor(
        of: find.byType(TextField),
        matching: find.byType(Flexible),
      ),
      findsOneWidget,
    );

    // Default test screen width is 800.
    final Size size = tester.getSize(find.byType(TextField));
    expect(size.width, 800.0);
  });

  testWidgets('TextField validation checks work', (WidgetTester tester) async {
    final surfaceController = SurfaceController(
      catalogs: [BasicCatalogItems.asCatalog()],
    );
    addTearDown(surfaceController.dispose);
    const surfaceId = 'validationTest';
    // Initialize with invalid value
    surfaceController.handleMessage(
      updateDataModel(
        surfaceId: surfaceId,
        path: DataPath('/myValue'),
        value: 'initial',
      ),
    );

    final List<JsonMap> components = [
      component(
        id: 'root',
        type: 'TextField',
        properties: {
          'label': 'Input',
          'value': {'path': 'inputValue'},
          'checks': [
            {
              'message': 'Must be at least 6 chars',
              'condition': {
                'call': 'length',
                'args': {
                  'value': {'path': 'inputValue'},
                  'min': 6,
                },
              },
            },
          ],
        },
      ),
    ];

    surfaceController.handleMessage(
      updateComponents(surfaceId: surfaceId, components: components),
    );
    surfaceController.handleMessage(
      createSurface(surfaceId: surfaceId, catalogId: basicCatalogId),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Surface(
            surfaceContext: surfaceController.contextFor(surfaceId),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify error text is shown
    expect(find.text('Must be at least 6 chars'), findsOneWidget);

    // Update with valid value
    await tester.enterText(find.byType(TextField), 'valid value');
    await tester.pumpAndSettle();

    expect(find.text('Must be at least 6 chars'), findsNothing);
  });
  testWidgets('TextField validation using condition wrapper and call key', (
    WidgetTester tester,
  ) async {
    final surfaceController = SurfaceController(
      catalogs: [BasicCatalogItems.asCatalog()],
    );
    addTearDown(surfaceController.dispose);
    const surfaceId = 'validationWrapperTest';
    // Initialize with invalid value (empty string)
    surfaceController.handleMessage(
      updateDataModel(surfaceId: surfaceId, path: DataPath('/name'), value: ''),
    );

    final List<JsonMap> components = [
      component(
        id: 'root',
        type: 'TextField',
        properties: {
          'label': 'Name',
          'value': {'path': '/name'},
          'checks': [
            {
              // Using "condition" wrapper and "call" instead of "func"
              // Args as list, as expected by function registry
              'condition': {
                'call': 'required',
                'args': {
                  'value': {'path': '/name'},
                },
              },
              'message': 'Name required',
            },
          ],
        },
      ),
    ];

    surfaceController.handleMessage(
      updateComponents(surfaceId: surfaceId, components: components),
    );
    surfaceController.handleMessage(
      createSurface(surfaceId: surfaceId, catalogId: basicCatalogId),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Surface(
            surfaceContext: surfaceController.contextFor(surfaceId),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Empty value should trigger required
    expect(find.text('Name required'), findsOneWidget);

    // Update with valid value
    await tester.enterText(find.byType(TextField), 'Alice');
    await tester.pumpAndSettle();

    expect(find.text('Name required'), findsNothing);
  });

  testWidgets('TextField gracefully handles non-string data model values', (
    WidgetTester tester,
  ) async {
    final surfaceController = SurfaceController(
      catalogs: [BasicCatalogItems.asCatalog()],
    );
    addTearDown(surfaceController.dispose);
    const surfaceId = 'validationTypeTest';
    // Initialize with an integer value
    surfaceController.handleMessage(
      updateDataModel(
        surfaceId: surfaceId,
        path: DataPath('/name'),
        value: 123,
      ),
    );

    final List<JsonMap> components = [
      component(
        id: 'root',
        type: 'TextField',
        properties: {
          'label': 'Name',
          'value': {'path': '/name'},
        },
      ),
    ];

    surfaceController.handleMessage(
      updateComponents(surfaceId: surfaceId, components: components),
    );
    surfaceController.handleMessage(
      createSurface(surfaceId: surfaceId, catalogId: basicCatalogId),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Surface(
            surfaceContext: surfaceController.contextFor(surfaceId),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The text field should convert the integer 123 to "123"
    expect(find.text('123'), findsOneWidget);
  });

  testWidgets('TextField with variant "obscured" hides what is typed', (
    WidgetTester tester,
  ) async {
    final SurfaceController surfaceController = await _pumpVariant(
      tester,
      variant: 'obscured',
    );

    final TextField field = tester.widget(find.byType(TextField));
    expect(field.obscureText, isTrue);
    // Obscured text is only valid on a single line.
    expect(field.maxLines, 1);
    // Neither of these should be able to observe a password.
    expect(field.autocorrect, isFalse);
    expect(field.enableSuggestions, isFalse);

    await tester.enterText(find.byType(TextField), 'hunter2');
    await tester.pumpAndSettle();

    expect(_value(surfaceController), 'hunter2');
    // The value reaches the data model, but is painted as obscuring characters
    // rather than as the typed text.
    final EditableText editable = tester.widget(find.byType(EditableText));
    expect(editable.obscureText, isTrue);
  });

  testWidgets('TextField with variant "longText" accepts multiple lines', (
    WidgetTester tester,
  ) async {
    final SurfaceController surfaceController = await _pumpVariant(
      tester,
      variant: 'longText',
    );

    final TextField field = tester.widget(find.byType(TextField));
    // A null `maxLines` lets the field grow with its content.
    expect(field.maxLines, isNull);
    expect(field.minLines, 3);
    expect(field.keyboardType, TextInputType.multiline);

    final double singleLineHeight = tester
        .getSize(find.byType(TextField))
        .height;

    await tester.enterText(
      find.byType(TextField),
      'Once upon a time\nthere was a text field\nthat could wrap\nand wrap',
    );
    await tester.pumpAndSettle();

    expect(
      _value(surfaceController),
      'Once upon a time\nthere was a text field\nthat could wrap\nand wrap',
    );
    // The field grew to fit the extra lines.
    expect(
      tester.getSize(find.byType(TextField)).height,
      greaterThan(singleLineHeight),
    );
  });

  testWidgets('TextField with variant "number" only accepts numbers', (
    WidgetTester tester,
  ) async {
    final SurfaceController surfaceController = await _pumpVariant(
      tester,
      variant: 'number',
    );

    final TextField field = tester.widget(find.byType(TextField));
    expect(field.maxLines, 1);
    expect(
      field.keyboardType,
      const TextInputType.numberWithOptions(signed: true, decimal: true),
    );

    // Non-numeric input is rejected outright.
    await tester.enterText(find.byType(TextField), 'abc');
    await tester.pumpAndSettle();
    expect(find.text('abc'), findsNothing);
    expect(_value(surfaceController), isNull);

    // Signed decimals are accepted, and stored as numbers rather than strings.
    await tester.enterText(find.byType(TextField), '-12.5');
    await tester.pumpAndSettle();
    expect(find.text('-12.5'), findsOneWidget);
    expect(_value(surfaceController), -12.5);

    // A rejected edit leaves the previously entered number untouched.
    await tester.enterText(find.byType(TextField), '-12.5e');
    await tester.pumpAndSettle();
    expect(find.text('-12.5'), findsOneWidget);
    expect(_value(surfaceController), -12.5);

    // The field can still be cleared.
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(_value(surfaceController), '');
  });
}
