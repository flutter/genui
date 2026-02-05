// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

void main() {
  group('Conversation', () {
    late A2uiTransportAdapter adapter;
    late SurfaceController controller;

    setUp(() {
      adapter = A2uiTransportAdapter();
      controller = SurfaceController(catalogs: []);
    });

    tearDown(() {
      adapter.dispose();
      controller.dispose();
    });

    test('updates isWaiting state during request', () async {
      final completer = Completer<void>();
      adapter = A2uiTransportAdapter(
        onSend: (message) async {
          await completer.future;
        },
      );

      final conversation = Conversation(
        transport: adapter,
        controller: controller,
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

      adapter = A2uiTransportAdapter(
        onSend: (message) async {
          capturedMessage = message;
        },
      );

      final conversation = Conversation(
        transport: adapter,
        controller: controller,
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
