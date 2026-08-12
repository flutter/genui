// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:simple_chat/chat_session.dart';
import 'package:simple_chat/primitives/message.dart';

import 'fake_ai_client.dart';

void main() {
  test('a request started while one is in flight is ignored', () async {
    final fakeAiClient = FakeAiClient()
      ..addResponse('The first response, long enough to arrive in chunks.')
      ..addResponse('The second response.');
    final session = TextOnlyChatSession(aiClient: fakeAiClient);
    addTearDown(session.dispose);

    // The app disables its text input while a request is in flight, but a
    // rendered surface stays interactive, so its buttons can submit at any
    // point. Both routes end up in the same place, so send a second message
    // without awaiting the first.
    final Future<void> first = session.sendMessage('one');
    await session.sendMessage('two');
    await first;

    // The second request never reached the agent.
    expect(fakeAiClient.receivedPrompts, ['one']);

    // The first response arrived in a single bubble, rather than being split in
    // two by the second request clearing the current message mid-stream.
    final List<Message> replies = session.messages
        .where((message) => !message.isUser)
        .toList();
    expect(replies, hasLength(1));
    expect(
      replies.single.text,
      'The first response, long enough to arrive in chunks.',
    );

    // The in-flight request owns the progress state until it finishes.
    expect(session.isProcessing, isFalse);
  });

  test('requests run one after another when awaited', () async {
    final fakeAiClient = FakeAiClient()
      ..addResponse('First.')
      ..addResponse('Second.');
    final session = TextOnlyChatSession(aiClient: fakeAiClient);
    addTearDown(session.dispose);

    await session.sendMessage('one');
    await session.sendMessage('two');

    expect(fakeAiClient.receivedPrompts, ['one', 'two']);

    // Each response gets a bubble of its own.
    expect(
      session.messages.where((message) => !message.isUser).map((m) => m.text),
      ['First.', 'Second.'],
    );
  });
}
