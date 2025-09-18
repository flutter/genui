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
      registry.register('Text', (context, component, properties, children) {
        return Text(properties['text'] as String? ?? '');
      });
      registry.register('ListView', (context, component, properties, children) {
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
        '{"messageType": "ComponentUpdate", "components": [{"id": "root", "type": "ListView", "children": {"template": {"componentId": "template", "dataBinding": "/items"}}}]}',
      );
      streamController.add(
        '{"messageType": "ComponentUpdate", "components": [{"id": "template", "type": "Text", "value": {"path": "/text"}}]}',
      );
      streamController.add(
        '''{"messageType": "DataModelUpdate", "nodes": [{"id": "data_root", "children": {"items": "items_node"}}, {"id": "items_node", "items": ["item1", "item2"]}]}''',
      );
      streamController.add(
        '''{"messageType": "DataModelUpdate", "nodes": [{"id": "item1", "children": {"text": "text1"}}, {"id": "text1", "value": "Item 1"}]}''',
      );
      streamController.add(
        '''{"messageType": "DataModelUpdate", "nodes": [{"id": "item2", "children": {"text": "text2"}}, {"id": "text2", "value": "Item 2"}]}''',
      );
      streamController.add(
        '''{"messageType": "UIRoot", "root": "root", "dataModelRoot": "data_root"}''',
      );
      await tester.pump();

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
        '{"messageType": "ComponentUpdate", "components": [{"id": "root", "type": "ListView", "children": {"template": {"componentId": "template", "dataBinding": "/items"}}}]}',
      );
      streamController.add(
        '{"messageType": "ComponentUpdate", "components": [{"id": "template", "type": "Text", "value": {"path": "/text"}}]}',
      );
      streamController.add(
        '''{"messageType": "DataModelUpdate", "nodes": [{"id": "data_root", "children": {"items": "items_node"}}, {"id": "items_node", "value": "not a list"}]}''',
      );
      streamController.add(
        '''{"messageType": "UIRoot", "root": "root", "dataModelRoot": "data_root"}''',
      );
      await tester.pump();

      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.textContaining('Item'), findsNothing);
    });
  });
}
