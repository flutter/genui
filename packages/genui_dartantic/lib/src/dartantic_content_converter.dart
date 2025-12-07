// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dartantic_interface/dartantic_interface.dart' as di;
import 'package:genui/genui.dart' as genui;

/// An exception thrown by this package.
class ContentConverterException implements Exception {
  /// Creates a [ContentConverterException] with the given [message].
  ContentConverterException(this.message);

  /// The message associated with the exception.
  final String message;

  @override
  String toString() => '$ContentConverterException: $message';
}

/// A class to convert between GenUI `ChatMessage` types and text/data formats
/// suitable for dartantic_ai.
///
/// Since dartantic_ai's Chat class manages conversation history automatically
/// and accepts simple string prompts, this converter primarily extracts text
/// content from GenUI messages.
class DartanticContentConverter {
  /// Converts a GenUI [genui.ChatMessage] to a text string suitable for
  /// sending to dartantic_ai.
  ///
  /// For [genui.UserMessage] and [genui.UserUiInteractionMessage], extracts
  /// the text content from all [genui.TextPart] instances.
  ///
  /// Throws [ContentConverterException] if the message type is not supported
  /// for conversion to a prompt.
  String toPromptText(genui.ChatMessage message) {
    switch (message) {
      case genui.UserMessage():
        return _extractText(message.parts);
      case genui.UserUiInteractionMessage():
        return _extractText(message.parts);
      case genui.AiTextMessage():
        return _extractText(message.parts);
      case genui.AiUiMessage():
        return _extractText(message.parts);
      case genui.ToolResponseMessage():
        throw ContentConverterException(
          'ToolResponseMessage cannot be converted to prompt text directly.',
        );
      case genui.InternalMessage():
        return message.text;
    }
  }

  /// Converts GenUI chat history to a list of dartantic [di.ChatMessage].
  ///
  /// Maps GenUI message types to dartantic roles:
  /// - [genui.UserMessage], [genui.UserUiInteractionMessage] ->
  ///   [di.ChatMessage.user]
  /// - [genui.AiTextMessage], [genui.AiUiMessage] -> [di.ChatMessage.model]
  /// - [genui.InternalMessage] -> skipped (not sent to AI)
  /// - [genui.ToolResponseMessage] -> skipped (handled internally by dartantic)
  ///
  /// If [systemInstruction] is provided, it is added as the first message
  /// using [di.ChatMessage.system].
  List<di.ChatMessage> toHistory(
    Iterable<genui.ChatMessage>? history, {
    String? systemInstruction,
  }) {
    final result = <di.ChatMessage>[];

    // Add system instruction first if provided
    if (systemInstruction != null) {
      result.add(di.ChatMessage.system(systemInstruction));
    }

    // Convert each GenUI message to dartantic format
    if (history != null) {
      for (final genui.ChatMessage message in history) {
        switch (message) {
          case genui.UserMessage():
            result.add(di.ChatMessage.user(_extractText(message.parts)));
          case genui.UserUiInteractionMessage():
            result.add(di.ChatMessage.user(_extractText(message.parts)));
          case genui.AiTextMessage():
            result.add(di.ChatMessage.model(_extractText(message.parts)));
          case genui.AiUiMessage():
            result.add(di.ChatMessage.model(_extractText(message.parts)));
          case genui.InternalMessage():
            // Skip internal messages - not sent to AI
            break;
          case genui.ToolResponseMessage():
            // Skip tool messages - dartantic handles tools internally
            break;
        }
      }
    }

    return result;
  }

  /// Extracts text content from a list of [genui.MessagePart] instances.
  ///
  /// Joins all [genui.TextPart] text values with newlines.
  String _extractText(List<genui.MessagePart> parts) {
    final textParts = <String>[];
    for (final part in parts) {
      switch (part) {
        case genui.TextPart():
          textParts.add(part.text);
        case genui.DataPart():
          // Include data as JSON-like text representation
          if (part.data != null) {
            textParts.add('Data: ${part.data}');
          }
        case genui.ImagePart():
          // Note: dartantic_ai may support images natively in some providers,
          // but for simplicity we just note the presence of an image.
          if (part.url != null) {
            textParts.add('Image at ${part.url}');
          } else {
            textParts.add('[Image data]');
          }
        case genui.ToolCallPart():
          // Tool calls are handled by dartantic internally
          break;
        case genui.ToolResultPart():
          // Tool results are handled by dartantic internally
          break;
        case genui.ThinkingPart():
          textParts.add('Thinking: ${part.text}');
      }
    }
    return textParts.join('\n');
  }
}
