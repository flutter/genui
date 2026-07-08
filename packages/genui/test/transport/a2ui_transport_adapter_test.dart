// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:a2ui_core/a2ui_core.dart' as core;
import 'package:genui/src/transport/a2ui_transport_adapter.dart';
import 'package:test/test.dart';

void main() {
  group('A2uiTransportAdapter', () {
    late A2uiTransportAdapter transportAdapter;

    setUp(() {
      transportAdapter = A2uiTransportAdapter();
    });

    tearDown(() {
      transportAdapter.dispose();
    });

    test('addChunk flows text to textStream', () async {
      final Future<dynamic> textFuture = expectLater(
        transportAdapter.incomingText,
        emitsInOrder(['Hello']),
      );
      transportAdapter.addChunk('Hello');
      await textFuture;
    });

    test('addChunk with message updates state', () async {
      // Using JSON block
      final json = '''```json
{"version": "v1.0", "createSurface": {"surfaceId": "test_chunk", "catalogId": "test-cat"}}
```''';

      final Future<dynamic> stateFuture = expectLater(
        transportAdapter.incomingMessages,
        emits(
          isA<core.CreateSurfaceMessage>().having(
            (e) => e.surfaceId,
            'id',
            'test_chunk',
          ),
        ),
      );

      transportAdapter.addChunk(json);
      await stateFuture;
    });

    test('addMessage updates state directly', () async {
      final msg = core.CreateSurfaceMessage(
        surfaceId: 'direct_msg',
        catalogId: 'direct-cat',
      );

      final Future<dynamic> stateFuture = expectLater(
        transportAdapter.incomingMessages,
        emits(
          isA<core.CreateSurfaceMessage>().having(
            (e) => e.surfaceId,
            'id',
            'direct_msg',
          ),
        ),
      );

      transportAdapter.addMessage(msg);
      await stateFuture;
    });

    test('incomingMessages emits parsable JSON messages', () async {
      final adapter = A2uiTransportAdapter();

      final Future<void> expectation = expectLater(
        adapter.incomingMessages,
        emits(
          predicate<core.A2uiMessage>((m) {
            return m is core.UpdateComponentsMessage &&
                m.components.length == 1 &&
                m.components.first['id'] == 'root';
          }),
        ),
      );

      adapter.addChunk('''```json
{"version": "v1.0", "updateComponents": {"surfaceId": "test", "components": [{"id": "root", "component": "Text", "properties": {"text": "Hello"}}]}}
```''');

      await expectation;
    });
  });
}
