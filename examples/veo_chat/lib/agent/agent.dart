// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;
import 'package:genui/genui.dart';
import 'package:logging/logging.dart';

import 'ai_client.dart';

typedef ChunkHandler = void Function(String chunk);

class AppAgent {
  AppAgent({AiClient? aiClient, required this.onChunkFromAgent})
    : aiClient = aiClient ?? DartanticAiClient();

  final AiClient aiClient;
  final ChunkHandler onChunkFromAgent;
  final List<dartantic.ChatMessage> _history = [];

  final Logger _logger = Logger('AppAgent');

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
