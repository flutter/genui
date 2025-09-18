// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gulf_client/gulf_client.dart';

void main() {
  group('GulfView', () {
    late StreamController<String> streamController;
    late GulfInterpreter interpreter;
    late WidgetRegistry registry;

    setUp(() {
      streamController = StreamController<String>();
      registry = WidgetRegistry();
      registry.register('TextProperties', (
        context,
        component,
        properties,
        children,
      ) {
        return Text(properties['text'] as String? ?? '');
      });
      registry.register('ColumnProperties', (
        context,
        component,
        properties,
        children,
      ) {
        return Column(children: children['children'] ?? []);
      });
      interpreter = GulfInterpreter(stream: streamController.stream);
    });

    testWidgets('shows loading indicator until ready', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GulfView(interpreter: interpreter, registry: registry),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders UI when ready', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GulfView(interpreter: interpreter, registry: registry),
        ),
      );

      streamController.add(
        '''{"componentUpdate": {"components": [{"id": "root", "componentProperties": {"Text": {"text": {"literalString": "Hello"}}}}]}}''',
      );
      streamController.add('{"beginRendering": {"root": "root"}}');
      await tester.pumpAndSettle();

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('displays error for cyclical layout', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GulfView(interpreter: interpreter, registry: registry),
        ),
      );

      streamController.add(
        '''{"componentUpdate": {"components": [{"id": "root", "componentProperties": {"Column": {"children": {"explicitList": ["root"]}}}}]}}''',
      );
      streamController.add('{"beginRendering": {"root": "root"}}');
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Error: cyclical layout detected'),
        findsOneWidget,
      );
    });

    testWidgets('displays error for missing builder', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GulfView(interpreter: interpreter, registry: registry),
        ),
      );

      streamController.add(
        '''{"componentUpdate": {"components": [{"id": "root", "componentProperties": {"MissingWidget": {}}}]}}''',
      );
      streamController.add('{"beginRendering": {"root": "root"}}');
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Unknown component type: MissingWidget'),
        findsOneWidget,
      );
    });

    testWidgets('displays error for missing component', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GulfView(interpreter: interpreter, registry: registry),
        ),
      );

      streamController.add('{"beginRendering": {"root": "root"}}');
      await tester.pumpAndSettle();

      expect(find.textContaining('Error: component not found'), findsOneWidget);
    });

    testWidgets('updates UI on data model change', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GulfView(interpreter: interpreter, registry: registry),
        ),
      );

      streamController.add(
        '''{"componentUpdate": {"components": [{"id": "root", "componentProperties": {"Text": {"text": {"path": "greeting"}}}}]}}''',
      );
      streamController.add(
        '{"dataModelUpdate": {"path": "greeting", "contents": "Initial"}}',
      );
      streamController.add('{"beginRendering": {"root": "root"}}');
      await tester.pumpAndSettle();

      expect(find.text('Initial'), findsOneWidget);

      streamController.add(
        '{"dataModelUpdate": {"path": "greeting", "contents": "Updated"}}',
      );
      await tester.pumpAndSettle();

      expect(find.text('Updated'), findsOneWidget);
    });

    testWidgets('builds card with child', (tester) async {
      registry.register('CardProperties', (
        context,
        component,
        properties,
        children,
      ) {
        return Card(child: children['child']!.first);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: GulfView(interpreter: interpreter, registry: registry),
        ),
      );

      streamController.add('''
        {"componentUpdate": { "components": [
          {"id": "root", "componentProperties": {"Card": {"child": "text_child"}}},
          {"id": "text_child", "componentProperties": {"Text": {"text": {"literalString": "Card Text"}}}}
        ]}}
        ''');
      streamController.add('{"beginRendering": {"root": "root"}}');
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Card Text'), findsOneWidget);
    });
  });
}
