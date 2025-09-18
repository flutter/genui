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
      registry.register('Text', (context, component, properties, children) {
        return Text(properties['text'] as String? ?? '');
      });
      registry.register('Column', (context, component, properties, children) {
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
        '''{"messageType": "ComponentUpdate", "components": [{"id": "root", "type": "Text", "value": {"literalString": "Hello"}}]}''',
      );
      streamController.add(
        '''{"messageType": "UIRoot", "root": "root", "dataModelRoot": "data_root"}''',
      );
      await tester.pump();

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('displays error for cyclical layout', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GulfView(interpreter: interpreter, registry: registry),
        ),
      );

      streamController.add(
        '''{"messageType": "ComponentUpdate", "components": [{"id": "root", "type": "Column", "children": {"explicitList": ["root"]}}]}''',
      );
      streamController.add(
        '''{"messageType": "UIRoot", "root": "root", "dataModelRoot": "data_root"}''',
      );
      await tester.pump();

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
        '''{"messageType": "ComponentUpdate", "components": [{"id": "root", "type": "MissingWidget"}]}''',
      );
      streamController.add(
        '''{"messageType": "UIRoot", "root": "root", "dataModelRoot": "data_root"}''',
      );
      await tester.pump();

      expect(
        find.textContaining('Error: unknown component type'),
        findsOneWidget,
      );
    });

    testWidgets('displays error for missing component', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GulfView(interpreter: interpreter, registry: registry),
        ),
      );

      streamController.add(
        '''{"messageType": "UIRoot", "root": "root", "dataModelRoot": "data_root"}''',
      );
      await tester.pump();

      expect(find.textContaining('Error: component not found'), findsOneWidget);
    });

    testWidgets('updates UI on data model change', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GulfView(interpreter: interpreter, registry: registry),
        ),
      );

      streamController.add(
        '''{"messageType": "ComponentUpdate", "components": [{"id": "root", "type": "Text", "value": {"path": "/greeting"}}]}''',
      );
      streamController.add(
        '''{"messageType": "DataModelUpdate", "nodes": [{"id": "data_root", "children": {"greeting": "greeting_node"}}, {"id": "greeting_node", "value": "Initial"}]}''',
      );
      streamController.add(
        '''{"messageType": "UIRoot", "root": "root", "dataModelRoot": "data_root"}''',
      );
      await tester.pump();

      expect(find.text('Initial'), findsOneWidget);

      streamController.add(
        '''{"messageType": "DataModelUpdate", "nodes": [{"id": "greeting_node", "value": "Updated"}]}''',
      );
      await tester.pump();

      expect(find.text('Updated'), findsOneWidget);
    });
  });
}
