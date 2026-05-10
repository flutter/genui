// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;
import 'package:genui/genui.dart';
import 'package:logging/logging.dart';

import 'ai_client.dart';

class SimpleChatAgent {
  SimpleChatAgent();

  final AiClient aiClient = DartanticAiClient();
  final List<dartantic.ChatMessage> history = [];
}

/// A [Transport] that wraps an [AiClient] to communicate with an LLM.
class SimpleChatA2aTransport implements Transport {
  SimpleChatA2aTransport();

  final SimpleChatAgent agent = SimpleChatAgent();
  final A2uiTransportAdapter _adapter = A2uiTransportAdapter();

  final Logger _logger = Logger('AiClientTransport');

  @override
  Stream<A2uiMessage> get incomingMessages => _adapter.incomingMessages;

  @override
  Stream<String> get incomingText => _adapter.incomingText;

  @override
  Future<void> sendRequest(ChatMessage message) async {
    final buffer = StringBuffer();
    for (final dartantic.StandardPart part in message.parts) {
      if (part.isUiInteractionPart) {
        buffer.write(part.asUiInteractionPart!.interaction);
      } else if (part is TextPart) {
        buffer.write(part.text);
      }
    }
    final text = buffer.toString();
    if (text.isEmpty) return;

    agent.history.add(dartantic.ChatMessage.user(text));

    try {
      final Stream<String> stream = agent.aiClient.sendStream(
        text,
        history: List.of(agent.history),
      );
      final fullResponseBuffer = StringBuffer();

      await for (final chunk in stream) {
        if (chunk.isNotEmpty) {
          fullResponseBuffer.write(chunk);
          _adapter.addChunk(chunk);
        }
      }

      agent.history.add(
        dartantic.ChatMessage.model(fullResponseBuffer.toString()),
      );
    } catch (exception, stackTrace) {
      _logger.severe('Error sending request', exception, stackTrace);
      rethrow;
    }
  }

  @override
  void dispose() {
    _adapter.dispose();
  }

  /// Adds a system message to the history.
  void addSystemMessage(String content) {
    agent.history.add(dartantic.ChatMessage.system(content));
  }
}
