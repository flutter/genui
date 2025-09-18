// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gulf_client/src/core/interpreter.dart';

void main() {
  group('GulfInterpreter', () {
    late StreamController<String> streamController;
    late GulfInterpreter interpreter;

    setUp(() {
      streamController = StreamController<String>();
      interpreter = GulfInterpreter(stream: streamController.stream);
    });

    test('initializes with correct default values', () {
      expect(interpreter.isReadyToRender, isFalse);
      expect(interpreter.rootComponentId, isNull);
    });

    testWidgets('processes ComponentUpdate and buffers components', (
      tester,
    ) async {
      streamController.add(
        '{"messageType": "ComponentUpdate", "runtimeType": "componentUpdate", '
        '"components": [{"id": "root", "type": "Column"}]}',
      );
      await tester.pump();
      expect(interpreter.getComponent('root'), isNotNull);
      expect(interpreter.isReadyToRender, isFalse);
    });

    testWidgets('processes DataModelUpdate and buffers nodes', (tester) async {
      streamController.add(
        '{"messageType": "DataModelUpdate", "runtimeType": "dataModelUpdate", '
        '"nodes": [{"id": "data_root", "value": "test"}]}',
      );
      await tester.pump();
      expect(interpreter.getDataNode('data_root'), isNotNull);
    });

    testWidgets('processes UIRoot and sets isReadyToRender', (tester) async {
      streamController.add(
        '{"messageType": "UIRoot", "runtimeType": "uiRoot", "root": "root", '
        '"dataModelRoot": "data_root"}',
      );
      await tester.pump();
      expect(interpreter.isReadyToRender, isTrue);
      expect(interpreter.rootComponentId, 'root');
    });

    testWidgets('notifies listeners on change', (tester) async {
      var callCount = 0;
      interpreter.addListener(() => callCount++);

      streamController.add(
        '{"messageType": "UIRoot", "runtimeType": "uiRoot", "root": "root", '
        '"dataModelRoot": "data_root"}',
      );
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

    test('throws an exception for unknown message type', () {
      const malformedJson = '{"messageType": "UnknownType"}';
      expect(
        () => interpreter.processMessage(malformedJson),
        throwsA(isA<Exception>()),
      );
    });

    test('handles malformed JSON gracefully', () {
      expect(
        () => interpreter.processMessage('{"messageType": "ComponentUpdate",'),
        throwsA(isA<FormatException>()),
      );
    });

    test('correctly processes a valid JSONL stream', () async {
      streamController.add(
        '{"messageType": "StreamHeader", "version": "1.0.0"}',
      );
      streamController.add(
        '{"messageType": "ComponentUpdate", "components": [{"id": "root", '
        '"type": "Column"}]}',
      );
      streamController.add(
        '{"messageType": "DataModelUpdate", "nodes": [{"id": "data_root", '
        '"children": {"user": "user_node"}}, {"id": "user_node", '
        '"value": "test_user"}]}',
      );
      streamController.add(
        '{"messageType": "UIRoot", "root": "root", '
        '"dataModelRoot": "data_root"}',
      );
      await streamController.close();

      expect(interpreter.isReadyToRender, isTrue);
      expect(interpreter.rootComponentId, 'root');
      expect(interpreter.getComponent('root')?.type, 'Column');
      expect(interpreter.resolveDataBinding('/user'), 'test_user');
    });

    test('resolveDataBinding returns null for invalid path', () async {
      streamController.add(
        '{"messageType": "DataModelUpdate", "nodes": [{"id": "data_root", '
        '"children": {"user": "user_node"}}, {"id": "user_node", '
        '"value": "test_user"}]}',
      );
      streamController.add(
        '{"messageType": "UIRoot", "root": "root", '
        '"dataModelRoot": "data_root"}',
      );
      await streamController.close();

      expect(interpreter.resolveDataBinding('/invalid/path'), isNull);
    });
  });
}
