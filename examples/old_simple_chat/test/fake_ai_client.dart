// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;
import 'package:genui/genui.dart';
import 'package:simple_chat/ai_client.dart';

/// A fake implementation of [AiClient] for testing.
class FakeAiClient implements AiClient {
  final StreamController<A2uiMessage> _a2uiMessageController =
      StreamController<A2uiMessage>.broadcast();

  final StreamController<String> _textResponseController =
      StreamController<String>.broadcast();

  // Queue of responses to send for each request.
  final List<String> _responses = [];

  final List<String> _receivedPrompts = [];
  List<String> get receivedPrompts => List.unmodifiable(_receivedPrompts);

  Stream<A2uiMessage> get a2uiMessageStream => _a2uiMessageController.stream;

  Stream<String> get textResponseStream => _textResponseController.stream;

  /// Adds a response to the queue.
  void addResponse(String response) {
    _responses.add(response);
  }

  @override
  Stream<String> sendStream(
    String prompt, {
    required List<dartantic.ChatMessage> history,
  }) async* {
    _receivedPrompts.add(prompt);
    if (_responses.isEmpty) {
      yield 'I have no response for that.';
      return;
    }

    final String response = _responses.removeAt(0);

    // Simulate streaming by yielding characters or chunks
    // For simplicity, we can just yield the whole thing or split it.
    // Let's split it into small chunks to simulate network.
    const chunkSize = 10;
    for (var i = 0; i < response.length; i += chunkSize) {
      final int end = (i + chunkSize < response.length)
          ? i + chunkSize
          : response.length;
      yield response.substring(i, end);
      // tiny delay
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  @override
  void dispose() {
    _a2uiMessageController.close();
    _textResponseController.close();
  }
}
