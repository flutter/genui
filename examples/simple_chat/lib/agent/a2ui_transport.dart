// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;
import 'package:genui/genui.dart';
import 'package:logging/logging.dart';

import 'ai_client.dart';

typedef _ChunkHandler = void Function(String chunk);

class _SimpleChatAgent {
  _SimpleChatAgent({AiClient? aiClient, required this.onChunkFromAgent})
    : aiClient = aiClient ?? DartanticAiClient();

  final AiClient aiClient;
  final _ChunkHandler onChunkFromAgent;
  final List<dartantic.ChatMessage> _history = [];

  final Logger _logger = Logger('_SimpleChatAgent');

  void addSystemMessage(String content) {
    _history.add(dartantic.ChatMessage.system(content));
  }

  Future<void> handleRequestFromRenderer(ChatMessage message) async {
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

    _history.add(dartantic.ChatMessage.user(text));

    try {
      final Stream<String> stream = aiClient.sendStream(
        text,
        history: List.of(_history),
      );
      final fullResponseBuffer = StringBuffer();

      await for (final chunk in stream) {
        if (chunk.isNotEmpty) {
          fullResponseBuffer.write(chunk);
          onChunkFromAgent(chunk);
        }
      }

      _history.add(dartantic.ChatMessage.model(fullResponseBuffer.toString()));
    } catch (exception, stackTrace) {
      _logger.severe('Error sending request', exception, stackTrace);
      rethrow;
    }
  }
}

/// A [Transport] that communicates with [_SimpleChatAgent].
class SimpleChatA2aTransport implements Transport {
  SimpleChatA2aTransport({AiClient? aiClient}) {
    _agent = _SimpleChatAgent(
      aiClient: aiClient,
      onChunkFromAgent: _adapter.addChunk,
    );
  }

  late final _SimpleChatAgent _agent;
  final A2uiTransportAdapter _adapter = A2uiTransportAdapter();

  @override
  Stream<A2uiMessage> get incomingMessages => _adapter.incomingMessages;

  @override
  Stream<String> get incomingText => _adapter.incomingText;

  @override
  Future<void> sendRequest(ChatMessage message) async {
    await _agent.handleRequestFromRenderer(message);
  }

  @override
  void dispose() => _adapter.dispose();

  /// Adds a system message to the history.
  void addSystemMessage(String content) => _agent.addSystemMessage(content);
}
