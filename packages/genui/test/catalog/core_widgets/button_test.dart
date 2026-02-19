// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui/src/interfaces/client_function.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

void main() {
  testWidgets('Button widget renders and handles taps', (
    WidgetTester tester,
  ) async {
    ChatMessage? message;
    final manager = SurfaceController(
      catalogs: [
        Catalog([
          BasicCatalogItems.button,
          BasicCatalogItems.text,
        ], catalogId: 'test_catalog'),
      ],
    );
    manager.onSubmit.listen((event) => message = event);
    const surfaceId = 'testSurface';
    final components = [
      const Component(
        id: 'root',
        type: 'Button',
        properties: {
          'child': 'button_text',
          'action': {
            'event': {'name': 'testAction'},
          },
        },
      ),
      const Component(
        id: 'button_text',
        type: 'Text',
        properties: {'text': 'Click Me'},
      ),
    ];
    manager.handleMessage(
      UpdateComponents(surfaceId: surfaceId, components: components),
    );
    manager.handleMessage(
      const CreateSurface(surfaceId: surfaceId, catalogId: 'test_catalog'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Surface(surfaceContext: manager.contextFor(surfaceId)),
        ),
      ),
    );

    final Finder buttonFinder = find.byType(ElevatedButton);
    expect(buttonFinder, findsOneWidget);
    expect(
      find.descendant(of: buttonFinder, matching: find.text('Click Me')),
      findsOneWidget,
    );

    expect(message, null);
    await tester.tap(find.byType(ElevatedButton));
    expect(message, isNotNull);
  });

  testWidgets('Button widget handles stream errors gracefully', (
    WidgetTester tester,
  ) async {
    ChatMessage? message;
    // Create a stream controller that we can use to emit errors
    final streamController = StreamController<Object?>.broadcast();

    final mockFunction = MockFunction(
      name: 'throwError',
      onExecute: (args, context) => streamController.stream,
    );

    final manager = SurfaceController(
      catalogs: [
        Catalog(
          [BasicCatalogItems.button, BasicCatalogItems.text],
          catalogId: 'test_catalog',
          functions: [mockFunction],
        ),
      ],
    );
    manager.onSubmit.listen((event) => message = event);

    const surfaceId = 'testSurface';
    final components = [
      const Component(
        id: 'root',
        type: 'Button',
        properties: {
          'child': 'button_text',
          'action': {'call': 'throwError'},
        },
      ),
      const Component(
        id: 'button_text',
        type: 'Text',
        properties: {'text': 'Click Me'},
      ),
    ];
    manager.handleMessage(
      UpdateComponents(surfaceId: surfaceId, components: components),
    );
    manager.handleMessage(
      const CreateSurface(surfaceId: surfaceId, catalogId: 'test_catalog'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Surface(surfaceContext: manager.contextFor(surfaceId)),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap the button to trigger the function call
    await tester.tap(find.byType(ElevatedButton));

    // Emit an error from the stream
    streamController.addError(Exception('Stream error'));

    // Pump to process the error
    await tester.pump();

    // Wait for the message to be received, pumping the widget tree
    var retries = 0;
    while (message == null && retries < 50) {
      await tester.pump(const Duration(milliseconds: 10));
      retries++;
    }

    // Verify error was reported
    expect(message, isNotNull);

    // The test passes if no unhandled exception crashes the test.
    await streamController.close();
    manager.dispose();
  });
}

class MockFunction implements ClientFunction {
  MockFunction({required this.name, required this.onExecute});

  @override
  final String name;

  final Stream<Object?> Function(JsonMap args, DataContext context) onExecute;

  @override
  Schema get argumentSchema => Schema.object();

  @override
  Stream<Object?> execute(JsonMap args, DataContext context) {
    return onExecute(args, context);
  }
}
