// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gulf_client/src/core/interpreter.dart';
import 'package:gulf_client/src/models/component.dart';

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

    test('throws an exception for unknown message type', () {
      const malformedJson = '{"unknownType": {}}';
      expect(
        () => interpreter.processMessage(malformedJson),
        throwsA(isA<Exception>()),
      );
    });

    test('handles malformed JSON gracefully', () {
      expect(
        () => interpreter.processMessage('{"componentUpdate":'),
        throwsA(isA<FormatException>()),
      );
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
  });
}
