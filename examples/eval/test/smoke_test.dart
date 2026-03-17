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

      await tester.chatSession.sendMessage('Hello!');
      final messages = await tester.waitForResponse();
      expect(messages.length, 1);
    },
  );
}

/// Helper class to manage the a chat session from simple chat example.
class _ChatSessionTester {
  _ChatSessionTester() {
    chatSession.addListener(() {});
  }

  Future<Iterable<sc.Message>> waitForResponse() async {
    final completer = Completer<void>();
    final int initialLength = chatSession.messages.length;
    chatSession.addListener(completer.complete);

    await completer.future;

    return chatSession.messages.getRange(
      initialLength,
      chatSession.messages.length,
    );
  }

  final sc.ChatSession chatSession = sc.ChatSession(
    aiClient: sc.DartanticAiClient(),
  );

  Future<void> sendMessage(String message) => chatSession.sendMessage(message);

  void dispose() {
    chatSession.dispose();
  }
}
