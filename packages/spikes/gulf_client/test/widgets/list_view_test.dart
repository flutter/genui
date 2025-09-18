// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gulf_client/gulf_client.dart';

void main() {
  group('GulfView ListView', () {
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
      registry.register('ListProperties', (
        context,
        component,
        properties,
        children,
      ) {
        return ListView(children: children['children'] ?? []);
      });
      interpreter = GulfInterpreter(stream: streamController.stream);
    });

    testWidgets('renders a list of items from a template', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GulfView(interpreter: interpreter, registry: registry),
          ),
        ),
      );

      streamController.add(
        '''{"componentUpdate": {"components": [{"id": "root", "componentProperties": {"List": {"children": {"template": {"componentId": "template", "dataBinding": "items"}}}}}]}}''',
      );
      streamController.add(
        '''{"componentUpdate": {"components": [{"id": "template", "componentProperties": {"Text": {"text": {"path": "text"}}}}]}}''',
      );
      streamController.add(
        '''{"dataModelUpdate": {"path": "items", "contents": [{"text": "Item 1"}, {"text": "Item 2"}]}}''',
      );
      streamController.add('{"beginRendering": {"root": "root"}}');
      await tester.pumpAndSettle();

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
    });

    testWidgets('renders empty when template data is not a list', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GulfView(interpreter: interpreter, registry: registry),
          ),
        ),
      );

      streamController.add(
        '''{"componentUpdate": {"components": [{"id": "root", "componentProperties": {"List": {"children": {"template": {"componentId": "template", "dataBinding": "items"}}}}}]}}''',
      );
      streamController.add(
        '''{"componentUpdate": {"components": [{"id": "template", "componentProperties": {"Text": {"text": {"path": "text"}}}}]}}''',
      );
      streamController.add(
        '{"dataModelUpdate": {"path": "items", "contents": "not a list"}}',
      );
      streamController.add('{"beginRendering": {"root": "root"}}');
      await tester.pumpAndSettle();

      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.textContaining('Item'), findsNothing);
    });
  });
}
