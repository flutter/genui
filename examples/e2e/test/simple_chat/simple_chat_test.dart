// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';

import 'chat_session_tester.dart';

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
    final tester = ChatSessionTester();
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
  }, timeout: const Timeout(Duration(minutes: 4)));
}
