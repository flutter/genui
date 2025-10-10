// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:a2ui_client/src/core/interpreter.dart';
import 'package:a2ui_client/src/models/component.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('A2uiInterpreter', () {
    late StreamController<String> streamController;
    late A2uiInterpreter interpreter;

    setUp(() {
      streamController = StreamController<String>();
      interpreter = A2uiInterpreter(stream: streamController.stream);
    });

    test('initializes with correct default values', () {
      expect(interpreter.isReadyToRender, isFalse);
      expect(interpreter.rootComponentId, isNull);
    });

    testWidgets('processes ComponentUpdate and buffers components', (
      tester,
    ) async {
      streamController.add(
        '''{"componentUpdate": {"components": [{"id": "root", "componentProperties": {"Column": {"children": {}}}}]}}''',
      );
      await tester.pump();
      expect(interpreter.getComponent('root'), isNotNull);
      expect(interpreter.isReadyToRender, isFalse);
    });

    testWidgets('processes DataModelUpdate and buffers nodes', (tester) async {
      streamController.add(
        '{"dataModelUpdate": {"path": "user.name", "contents": "John Doe"}}',
      );
      await tester.pump();
      expect(interpreter.resolveDataBinding('user.name'), 'John Doe');
    });

    testWidgets('processes BeginRendering and sets isReadyToRender', (
      tester,
    ) async {
      streamController.add('{"beginRendering": {"root": "root"}}');
      await tester.pump();
      expect(interpreter.isReadyToRender, isTrue);
      expect(interpreter.rootComponentId, 'root');
    });

    testWidgets('notifies listeners on change', (tester) async {
      var callCount = 0;
      interpreter.addListener(() => callCount++);

      streamController.add('{"beginRendering": {"root": "root"}}');
      await tester.pump();
      expect(callCount, 1);
    });

    testWidgets('handles empty message string gracefully', (tester) async {
      var callCount = 0;
      interpreter.addListener(() => callCount++);
      streamController.add('');
      await tester.pump();
      expect(callCount, 0);
    });

    test('throws an exception for unknown message type', () async {
      const malformedJson = '{"unknownType": {}}';
      interpreter.processMessage(malformedJson);
      expect(interpreter.error, isNotNull);
    });

    test('handles malformed JSON gracefully', () {
      interpreter.processMessage('{"componentUpdate":');
      expect(interpreter.error, isNotNull);
    });

    test('correctly processes a valid JSONL stream', () async {
      streamController.add('{"streamHeader": {"version": "1.0.0"}}');
      streamController.add(
        '''{"componentUpdate": {"components": [{"id": "root", "componentProperties": {"Column": {"children": {}}}}]}}''',
      );
      streamController.add(
        '''{"dataModelUpdate": {"path": "user", "contents": {"name": "test_user"}}}''',
      );
      streamController.add('{"beginRendering": {"root": "root"}}');
      await streamController.close();

      expect(interpreter.isReadyToRender, isTrue);
      expect(interpreter.rootComponentId, 'root');
      final component = interpreter.getComponent('root');
      expect(component, isNotNull);
      expect(component?.componentProperties, isA<ColumnProperties>());
      expect(interpreter.resolveDataBinding('user.name'), 'test_user');
    });

    test('resolveDataBinding returns null for invalid path', () async {
      streamController.add(
        '''{"dataModelUpdate": {"path": "user", "contents": {"name": "test_user"}}}''',
      );
      streamController.add('{"beginRendering": {"root": "root"}}');
      await streamController.close();

      expect(interpreter.resolveDataBinding('invalid.path'), isNull);
    });

    test('handles data model updates with array paths', () {
      final interpreter = A2uiInterpreter(stream: const Stream.empty());
      const message = '''
      {"dataModelUpdate": {"path": "user.addresses[0].street", "contents": "123 Main St"}}
      ''';
      interpreter.processMessage(message);
      final address = interpreter.resolveDataBinding(
        'user.addresses[0].street',
      );
      expect(address, '123 Main St');

      const message2 = '''
      {"dataModelUpdate": {"path": "user.addresses[1]", "contents": {"street": "456 Oak Ave"}}}
      ''';
      interpreter.processMessage(message2);
      final street = interpreter.resolveDataBinding('user.addresses[1].street');
      expect(street, '456 Oak Ave');
    });

    test('updateData updates the data model and notifies listeners', () {
      var callCount = 0;
      interpreter.addListener(() => callCount++);

      interpreter.updateData('user.name', 'Jane Doe');

      expect(interpreter.resolveDataBinding('user.name'), 'Jane Doe');
      expect(callCount, 1);
    });

    test('sets error when root data model is not a map', () {
      final interpreter = A2uiInterpreter(stream: const Stream.empty());
      const message = '''
      {"dataModelUpdate": {"contents": "not a map"}}
      ''';
      interpreter.processMessage(message);
      expect(interpreter.error, isNotNull);
      expect(interpreter.error, 'Data model root must be a JSON object.');
    });
  });
}
