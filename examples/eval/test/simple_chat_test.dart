// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:simple_chat/simple_chat.dart' as sc;

import 'test_infra/issue_reporter.dart';

const List<String> _userMessages = [
  'Hello!',
  'Can you give me options how you can help me?',
  'I want to create a todo list, to build a house',
  'Add a task "Hire architect" to my todo list',
  'Mark the task "Hire architect" as completed',
  'Remove the task "Hire architect"',
  'Clear my todo list',
];

void main() {
  test('Model respects configuration of prompt builder '
      'in the simple chat example.', () async {
    final tester = _ChatSessionTester();
    addTearDown(tester.dispose);

    for (final String message in _userMessages) {
      await tester.sendMessageAndWaitForResponse(message);
    }

    final Iterable<String> surfaceIds = tester.surfaceIds();

    expect(
      surfaceIds.length,
      isPositive,
      reason: 'Model should produce surfaces',
    );

    for (final ConversationEvent event in tester.events) {
      print(event.runtimeType);
    }
  });
}

/// Helper class to manage a chat session from simple chat example.
class _ChatSessionTester {
  _ChatSessionTester() {
    chatSession.conversation.events.listen(events.add);
  }

  final IssueReporter reporter = IssueReporter();
  final List<ConversationEvent> events = [];
  final sc.ChatSession chatSession = sc.ChatSession(
    aiClient: sc.DartanticAiClient(),
  );

  Future<void> _waitForProcessingToComplete() async {
    if (!chatSession.isProcessing) return;

    final completer = Completer<void>();
    void listener() {
      if (!chatSession.isProcessing) {
        completer.complete();
      }
    }

    chatSession.addListener(listener);
    await completer.future;
    chatSession.removeListener(listener);
  }

  Future<void> sendMessageAndWaitForResponse(String message) async {
    await chatSession.sendMessage(message);
    reporter.expect(
      chatSession.isProcessing,
      'chatSession.isProcessing should be true after sending a message',
    );

    await _waitForProcessingToComplete();
  }

  Iterable<String> surfaceIds() {
    return chatSession.messages
        .where((m) => !m.isUser)
        .map((m) => m.surfaceId)
        .whereType<String>();
  }

  void dispose() {
    chatSession.dispose();
  }
}
