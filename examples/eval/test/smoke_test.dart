// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:simple_chat/simple_chat.dart' as sc;

void main() {
  test(
    'Model respects configuration of prompt builder in the simple chat example.',
    () async {
      final tester = _ChatSessionTester();
      addTearDown(tester.dispose);

      final Iterable<sc.Message> messages = await tester
          .sendMessageAndWaitForResponse('Hello!');
      expect(messages.length, 1);
    },
  );
}

/// Helper class to manage the a chat session from simple chat example.
class _ChatSessionTester {
  _ChatSessionTester() {
    chatSession.addListener(() {});
  }

  final sc.ChatSession chatSession = sc.ChatSession(
    aiClient: sc.DartanticAiClient(),
  );

  Future<Iterable<sc.Message>> sendMessageAndWaitForResponse(
    String message,
  ) async {
    print('!!! Length before send: ${chatSession.messages.length}');
    await chatSession.sendMessage(message);
    print('Length after send: ${chatSession.messages.length}');
    final completer = Completer<void>();
    final int initialLength = chatSession.messages.length;

    chatSession.addListener(() {
      if (!chatSession.isProcessing) {
        completer.complete();
      }
    });

    await completer.future;

    print('!!!Length after processing: ${chatSession.messages.length}');

    return chatSession.messages.getRange(
      initialLength,
      chatSession.messages.length,
    );
  }

  void dispose() {
    chatSession.dispose();
  }
}
