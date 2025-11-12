// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart' as firebase_ai;
import 'package:genui/genui.dart';

/// An exception thrown by this package.
class ContentConverterException implements Exception {
  /// Creates an [ContentConverterException] with the given [message].
  ContentConverterException(this.message);

  /// The message associated with the exception.
  final String message;

  @override
  String toString() => '$ContentConverterException: $message';
}

/// A class to convert between the generic `ChatMessage` and the `firebase_ai`
/// specific `Content` classes.
///
/// This class is responsible for translating the abstract [ChatMessage]
/// representation into the concrete `firebase_ai.Content` representation
/// required by the `firebase_ai` package.
///
/// **Note on Image Handling:** [ImagePart] instances that are provided with
/// only a `url` (and no `bytes` or `base64` data) will be converted to a
/// simple text representation of the URL (e.g., "Image at {url}"). The image
/// data is not automatically fetched from the URL by this converter.
class GeminiContentConverter {
  /// Converts a list of `ChatMessage` objects to a list of
  /// `firebase_ai.Content` objects.
  List<firebase_ai.Content> toFirebaseAiContent(
    Iterable<ChatMessage> messages,
  ) {
    final result = <firebase_ai.Content>[];
    for (final message in messages) {
      final (String? role, List<firebase_ai.Part> parts) = switch (message) {
        UserMessage() => ('user', _convertParts(message.parts)),
        UserUiInteractionMessage() => ('user', _convertParts(message.parts)),
        AiTextMessage() => ('model', _convertParts(message.parts)),
        ToolResponseMessage() => ('user', _convertParts(message.results)),
        AiUiMessage() => ('model', _convertParts(message.parts)),
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
        case DataPart():
          result.add(
            firebase_ai.InlineDataPart(
              'application/json',
              utf8.encode(jsonEncode(part.data)),
            ),
          );
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
            result.add(firebase_ai.TextPart('Image at ${part.url}'));
          } else {
            throw ContentConverterException('ImagePart has no data.');
          }
        case ToolCallPart():
          result.add(firebase_ai.FunctionCall(part.toolName, part.arguments));
        case ToolResultPart():
          result.add(
            firebase_ai.FunctionResponse(
              part.callId,
              // The result from ToolResultPart is a JSON string, but
              // FunctionResponse expects a Map.
              jsonDecode(part.result) as JsonMap,
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
