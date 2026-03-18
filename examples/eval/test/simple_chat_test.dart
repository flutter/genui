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

    expect(
      tester.surfaceIds().length,
      isPositive,
      reason: 'Model should produce surfaces',
    );

    tester.verifyEvents();

    tester.failIfIssuesFound();
  }, timeout: const Timeout(Duration(seconds: 120)));
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
    await _waitForProcessingToComplete();
  }

  Iterable<String> surfaceIds() {
    return chatSession.messages
        .where((m) => !m.isUser)
        .map((m) => m.surfaceId)
        .whereType<String>();
  }

  void verifyEvents() {
    final created = <String>[];
    final removed = <String>[];
    final updated = <String>[];
    var content = 0;
    var waiting = 0;
    final errors = <String>[];
    for (final ConversationEvent event in events) {
      switch (event) {
        case ConversationSurfaceAdded():
          created.add(event.surfaceId);
        case ConversationComponentsUpdated():
          updated.add(event.surfaceId);
        case ConversationSurfaceRemoved():
          removed.add(event.surfaceId);
        case ConversationContentReceived():
          content++;
        case ConversationWaiting():
          waiting++;
        case ConversationError():
          errors.add(event.error.toString());
      }
    }

    print('Conversation summary:');
    print('  Created surfaces: $created');
    print('  Removed surfaces: $removed');
    print('  Updated surfaces: $updated');
    print('  Text content: $content');
    print('  Waiting: $waiting');
    print('  Errors: $errors');

    reporter.expect(errors.isEmpty, 'No errors should occur');
    reporter.expect(
      updated.isEmpty,
      'In chat setup surfaces should not be updated',
    );
  }

  void failIfIssuesFound() => reporter.failIfIssuesFound();

  void dispose() {
    chatSession.dispose();
  }
}
