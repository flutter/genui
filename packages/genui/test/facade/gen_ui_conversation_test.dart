// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

void main() {
  group('GenUiConversation', () {
    late A2uiTransportAdapter adapter;
    late GenUiEngine engine;

    setUp(() {
      adapter = A2uiTransportAdapter();
      engine = GenUiEngine(catalogs: []);
    });

    tearDown(() {
      adapter.dispose();
      engine.dispose();
    });

    test('updates isWaiting state during request', () async {
      final completer = Completer<void>();
      final conversation = GenUiConversation(
        adapter: adapter,
        engine: engine,
        onSend: (message) async {
          await completer.future;
        },
      );

      expect(conversation.state.value.isWaiting, isFalse);

      final Future<void> future = conversation.sendRequest(
        ChatMessage.user('hi', parts: [UiInteractionPart.create('hi')]),
      );

      expect(conversation.state.value.isWaiting, isTrue);

      completer.complete();
      await future;

      expect(conversation.state.value.isWaiting, isFalse);
      conversation.dispose();
    });

    test('calls onSend with correct message', () async {
      ChatMessage? capturedMessage;

      final conversation = GenUiConversation(
        adapter: adapter,
        engine: engine,
        onSend: (message) async {
          capturedMessage = message;
        },
      );

      // Send first message
      final firstMessage = ChatMessage.user('First');
      await conversation.sendRequest(firstMessage);

      expect(capturedMessage, firstMessage);

      // Send second message
      final secondMessage = ChatMessage.user('Second');
      await conversation.sendRequest(secondMessage);

      expect(capturedMessage, secondMessage);

      conversation.dispose();
    });
  });
}
