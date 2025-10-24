// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:dartantic_interface/dartantic_interface.dart' as dartantic;
import 'package:flutter_genui/flutter_genui.dart';

/// A class to convert between the generic `ChatMessage` and the `dartantic_interface`
/// specific `ChatMessage` classes.
///
/// This class is responsible for translating the abstract [ChatMessage]
/// representation into the concrete `dartantic.ChatMessage` representation
/// required by the `dartantic_ai` package.
class DartanticContentConverter {
  /// Converts a list of `ChatMessage` objects to a list of
  /// `dartantic.ChatMessage` objects.
  List<dartantic.ChatMessage> toDartanticMessages(
    Iterable<ChatMessage> messages,
  ) {
    final result = <dartantic.ChatMessage>[];
    for (final message in messages) {
      final dartanticMessage = _convertMessage(message);
      if (dartanticMessage != null) {
        result.add(dartanticMessage);
      }
    }
    return result;
  }

  /// Converts a single `ChatMessage` to a `dartantic.ChatMessage`.
  dartantic.ChatMessage? _convertMessage(ChatMessage message) {
    return switch (message) {
      UserMessage() => _convertUserMessage(message),
      UserUiInteractionMessage() => _convertUserUiInteractionMessage(message),
      AiTextMessage() => _convertAiTextMessage(message),
      ToolResponseMessage() => _convertToolResponseMessage(message),
      AiUiMessage() => _convertAiUiMessage(message),
      InternalMessage() => _convertInternalMessage(message),
    };
  }

  /// Converts a user message to dartantic format.
  dartantic.ChatMessage _convertUserMessage(UserMessage message) {
    final parts = _convertParts(message.parts);
    return dartantic.ChatMessage(
      role: dartantic.ChatMessageRole.user,
      parts: parts,
    );
  }

  /// Converts a user UI interaction message to dartantic format.
  dartantic.ChatMessage _convertUserUiInteractionMessage(
    UserUiInteractionMessage message,
  ) {
    final parts = _convertParts(message.parts);
    return dartantic.ChatMessage(
      role: dartantic.ChatMessageRole.user,
      parts: parts,
    );
  }

  /// Converts an AI text message to dartantic format.
  dartantic.ChatMessage _convertAiTextMessage(AiTextMessage message) {
    final parts = _convertParts(message.parts);
    return dartantic.ChatMessage(
      role: dartantic.ChatMessageRole.model,
      parts: parts,
    );
  }

  /// Converts an AI UI message to dartantic format.
  dartantic.ChatMessage _convertAiUiMessage(AiUiMessage message) {
    final parts = _convertParts(message.parts);
    return dartantic.ChatMessage(
      role: dartantic.ChatMessageRole.model,
      parts: parts,
    );
  }

  /// Converts a tool response message to dartantic format.
  dartantic.ChatMessage _convertToolResponseMessage(
    ToolResponseMessage message,
  ) {
    // Convert tool results to dartantic tool parts
    final toolParts = <dartantic.ToolPart>[];
    for (final result in message.results) {
      toolParts.add(
        dartantic.ToolPart.result(
          id: result.callId,
          name: 'tool', // We don't have the tool name in ToolResultPart
          result: result.result,
        ),
      );
    }
    return dartantic.ChatMessage(
      role: dartantic.ChatMessageRole.user, // Tool responses are typically user role
      parts: toolParts,
    );
  }

  /// Converts an internal message to dartantic format.
  dartantic.ChatMessage _convertInternalMessage(InternalMessage message) {
    return dartantic.ChatMessage(
      role: dartantic.ChatMessageRole.system,
      parts: [dartantic.TextPart(message.text)],
    );
  }

  /// Converts message parts to dartantic parts.
  List<dartantic.Part> _convertParts(List<MessagePart> parts) {
    final result = <dartantic.Part>[];
    for (final part in parts) {
      final dartanticPart = _convertPart(part);
      if (dartanticPart != null) {
        result.add(dartanticPart);
      }
    }
    return result;
  }

  /// Converts a single message part to dartantic part.
  dartantic.Part? _convertPart(MessagePart part) {
    return switch (part) {
      TextPart() => dartantic.TextPart(part.text),
      ImagePart() => _convertImagePart(part),
      ToolCallPart() => _convertToolCallPart(part),
      ToolResultPart() => _convertToolResultPart(part),
      ThinkingPart() => dartantic.TextPart('Thinking: ${part.text}'),
    };
  }

  /// Converts an image part to dartantic part.
  dartantic.Part? _convertImagePart(ImagePart part) {
    if (part.bytes != null) {
      return dartantic.DataPart(
        part.bytes!,
        mimeType: part.mimeType!,
      );
    } else if (part.base64 != null) {
      return dartantic.DataPart(
        base64.decode(part.base64!),
        mimeType: part.mimeType!,
      );
    } else if (part.url != null) {
      // For URL-based images, we'll represent them as link parts
      return dartantic.LinkPart(
        part.url!,
        mimeType: part.mimeType,
      );
    } else {
      throw AiClientException('ImagePart has no data.');
    }
  }

  /// Converts a tool call part to dartantic part.
  dartantic.Part _convertToolCallPart(ToolCallPart part) {
    return dartantic.ToolPart.call(
      id: part.id,
      name: part.toolName,
      arguments: part.arguments,
    );
  }

  /// Converts a tool result part to dartantic part.
  dartantic.Part _convertToolResultPart(ToolResultPart part) {
    return dartantic.ToolPart.result(
      id: part.callId,
      name: 'tool', // We don't have the tool name in ToolResultPart
      result: part.result,
    );
  }
}
