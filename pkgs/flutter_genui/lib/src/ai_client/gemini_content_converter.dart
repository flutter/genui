// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart' as firebase_ai;

import '../model/chat_message.dart';
import 'ai_client.dart';

/// A class to convert between the generic `ChatMessage` and the `firebase_ai`
/// specific `Content` classes.
class GeminiContentConverter {
  /// Converts a list of `ChatMessage` objects to a list of
  /// `firebase_ai.Content` objects.
  List<firebase_ai.Content> toFirebaseAiContent(List<ChatMessage> messages) {
    final result = <firebase_ai.Content>[];
    for (final message in messages) {
      final (String? role, List<firebase_ai.Part> parts) = switch (message) {
        UserMessage() => ('user', _convertParts(message.parts)),
        AssistantMessage() => ('model', _convertParts(message.parts)),
        ToolResponseMessage() => ('user', _convertParts(message.results)),
        UiResponseMessage() => (
          'user',
          [
            firebase_ai.TextPart(
              'The following is the current UI state that you have generated, '
              'for your information. You should use this to inform your '
              'decision about what to do next. The user is seeing this UI.\n\n'
              '${jsonEncode(message.definition)}',
            ),
          ],
        ),
        InternalMessage() => (null, <firebase_ai.Part>[]), // Not sent to model
      };

      if (role != null && parts.isNotEmpty) {
        result.add(firebase_ai.Content(role, parts));
      }
    }
    return result;
  }

  List<firebase_ai.Part> _convertParts(List<MessagePart> parts) {
    final result = <firebase_ai.Part>[];
    for (final part in parts) {
      switch (part) {
        case TextPart():
          result.add(firebase_ai.TextPart(part.text));
        case ImagePart():
          if (part.bytes != null) {
            result.add(firebase_ai.InlineDataPart(part.mimeType!, part.bytes!));
          } else if (part.base64 != null) {
            result.add(
              firebase_ai.InlineDataPart(
                part.mimeType!,
                base64.decode(part.base64!),
              ),
            );
          } else if (part.url != null) {
            // TODO(gspencer): Gemini doesn't directly support URLs in parts
            // like some other APIs. A more complete implementation would
            // download the data. For now, we'll just send a text
            // representation.
            result.add(firebase_ai.TextPart('Image at ${part.url}'));
          } else {
            throw AiClientException('ImagePart has no data.');
          }
        case ToolCallPart():
          result.add(firebase_ai.FunctionCall(part.toolName, part.arguments));
        case ToolResultPart():
          result.add(
            firebase_ai.FunctionResponse(
              part.callId,
              // The result from ToolResultPart is a JSON string, but
              // FunctionResponse expects a Map.
              jsonDecode(part.result) as Map<String, Object?>,
            ),
          );
        case ThinkingPart():
          // Represent thoughts as text.
          result.add(firebase_ai.TextPart('Thinking: ${part.text}'));
      }
    }
    return result;
  }
}
