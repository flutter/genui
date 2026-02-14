// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:genui/src/model/a2ui_message.dart';

import 'package:genui/src/transport/a2ui_transport_adapter.dart';
import 'package:test/test.dart';

void main() {
  group('A2uiTransportAdapter', () {
    late A2uiTransportAdapter controller;

    setUp(() {
      controller = A2uiTransportAdapter();
    });

    tearDown(() {
      controller.dispose();
    });

    test('addChunk flows text to textStream', () async {
      final Future<dynamic> textFuture = expectLater(
        controller.incomingText,
        emitsInOrder(['Hello']),
      );
      controller.addChunk('Hello');
      await textFuture;
    });

    test('addChunk with message updates state', () async {
      // Using JSON block
      final json = '''```json
{"version": "v0.9", "createSurface": {"surfaceId": "test_chunk", "catalogId": "test-cat"}}
```''';

      final Future<dynamic> stateFuture = expectLater(
        controller.incomingMessages,
        emits(
          isA<CreateSurface>().having((e) => e.surfaceId, 'id', 'test_chunk'),
        ),
      );

      controller.addChunk(json);
      await stateFuture;
    });

    test('addMessage updates state directly', () async {
      final msg = const CreateSurface(
        surfaceId: 'direct_msg',
        catalogId: 'direct-cat',
      );

      final Future<dynamic> stateFuture = expectLater(
        controller.incomingMessages,
        emits(
          isA<CreateSurface>().having((e) => e.surfaceId, 'id', 'direct_msg'),
        ),
      );

      controller.addMessage(msg);
      await stateFuture;
    });

    test('incomingMessages emits parsable JSON messages', () async {
      final adapter = A2uiTransportAdapter();

      final Future<void> expectation = expectLater(
        adapter.incomingMessages,
        emits(
          predicate<A2uiMessage>((m) {
            return m is UpdateComponents &&
                m.components.length == 1 &&
                m.components.first.id == 'root';
          }),
        ),
      );

      adapter.addChunk('''```json
{"version": "v0.9", "updateComponents": {"surfaceId": "test", "components": [{"id": "root", "component": "Text", "properties": {"text": "Hello"}}]}}
```''');

      await expectation;
    });
  });
}
