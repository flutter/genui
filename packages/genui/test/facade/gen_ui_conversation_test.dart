// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

void main() {
  group('GenUiConversation', () {
    late GenUiController controller;
    late A2uiMessageProcessor processor;

    setUp(() {
      controller = GenUiController();
      processor = A2uiMessageProcessor(catalogs: []);
    });

    tearDown(() {
      controller.dispose();
      processor.dispose();
    });

    test('updates isProcessing state during request', () async {
      final completer = Completer<void>();
      final conversation = GenUiConversation(
        controller: controller,
        messageSink: processor,
        host: processor,
        onSend: (message, history) async {
          await completer.future;
        },
      );

      expect(conversation.isProcessing.value, isFalse);

      final Future<void> future = conversation.sendRequest(
        ChatMessage.user('', parts: [UiInteractionPart.create('hi')]),
      );

      expect(conversation.isProcessing.value, isTrue);

      completer.complete();
      await future;

      expect(conversation.isProcessing.value, isFalse);
      conversation.dispose();
    });

    test('calls onSend with correct message and history', () async {
      ChatMessage? capturedMessage;
      Iterable<ChatMessage>? capturedHistory;

      final conversation = GenUiConversation(
        controller: controller,
        messageSink: processor,
        host: processor,
        onSend: (message, history) async {
          capturedMessage = message;
          capturedHistory = history;
        },
      );

      // Send first message
      final firstMessage = ChatMessage.user('First');
      await conversation.sendRequest(firstMessage);

      expect(capturedMessage, firstMessage);
      expect(capturedHistory, isEmpty);
      expect(conversation.conversation.value.last, firstMessage);

      // Send second message
      final secondMessage = ChatMessage.user('Second');
      await conversation.sendRequest(secondMessage);

      expect(capturedMessage, secondMessage);
      expect(capturedHistory, isNotEmpty);
      expect(capturedHistory!.last, firstMessage);
      expect(conversation.conversation.value.length, 2);
      expect(conversation.conversation.value.last, secondMessage);

      conversation.dispose();
    });
  });
}
