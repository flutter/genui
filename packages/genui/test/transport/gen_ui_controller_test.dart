// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:genui/src/core/a2ui_message_processor.dart';
import 'package:genui/src/model/a2ui_message.dart';
import 'package:genui/src/transport/gen_ui_controller.dart';
import 'package:test/test.dart';

void main() {
  group('GenUiController', () {
    late GenUiController controller;

    setUp(() {
      controller = GenUiController(catalogs: []);
    });

    tearDown(() {
      controller.dispose();
    });

    test('addChunk flows text to textStream', () async {
      final Future<dynamic> textFuture = expectLater(
        controller.textStream,
        emitsInOrder(['Hello']),
      );
      controller.addChunk('Hello');
      await textFuture;
    });

    test('addChunk with message updates state', () async {
      // Using JSON block
      final json = '''```json
{"createSurface": {"surfaceId": "test_chunk", "catalogId": "test-cat"}}
```''';

      final Future<dynamic> stateFuture = expectLater(
        controller.stateStream,
        emits(
          isA<SurfaceAdded>().having((e) => e.surfaceId, 'id', 'test_chunk'),
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
        controller.stateStream,
        emits(
          isA<SurfaceAdded>().having((e) => e.surfaceId, 'id', 'direct_msg'),
        ),
      );

      controller.addMessage(msg);
      await stateFuture;
    });
  });
}
