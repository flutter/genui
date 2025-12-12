// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Copyright 2025 The Flutter Authors. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;
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
  /// Converts a GenUI [genui.ChatMessage] into a prompt string plus dartantic
  /// parts so we can send full multimodal content (text, data, tools).
  ({String prompt, List<dartantic.Part> parts}) toPromptAndParts(
    genui.ChatMessage message,
  ) {
    return switch (message) {
      genui.UserMessage() => (
        prompt: _extractText(message.parts),
        parts: _toPartsWithoutText(message.parts),
      ),
      genui.UserUiInteractionMessage() => (
        prompt: _extractText(message.parts),
        parts: _toPartsWithoutText(message.parts),
      ),
      genui.AiTextMessage() => (
        prompt: _extractText(message.parts),
        parts: _toPartsWithoutText(message.parts),
      ),
      genui.AiUiMessage() => (
        prompt: _extractText(message.parts),
        parts: _toPartsWithoutText(message.parts),
      ),
      genui.ToolResponseMessage() => (
        prompt: _extractToolResponseText(message.results),
        parts: _toolResultPartsToDiParts(message.results),
      ),
      genui.InternalMessage() => (
        prompt: message.text,
        parts: const <dartantic.Part>[],
      ),
    };
  }

  /// Converts GenUI chat history to a list of dartantic
  /// [dartantic.ChatMessage].
  ///
  /// Maps GenUI message types to dartantic roles:
  /// - [genui.UserMessage], [genui.UserUiInteractionMessage] ->
  ///   [dartantic.ChatMessage.user]
  /// - [genui.AiTextMessage], [genui.AiUiMessage] ->
  ///   [dartantic.ChatMessage.model]
  /// - [genui.ToolResponseMessage] -> [dartantic.ChatMessage.user] with tool
  ///   results
  /// - [genui.InternalMessage] -> [dartantic.ChatMessage.system]
  ///
  /// If [systemInstruction] is provided, it is added as the first message using
  /// [dartantic.ChatMessage.system].
  List<dartantic.ChatMessage> toHistory(
    Iterable<genui.ChatMessage>? history, {
    String? systemInstruction,
  }) {
    final result = <dartantic.ChatMessage>[];

    // Add system instruction first if provided
    if (systemInstruction != null) {
      result.add(dartantic.ChatMessage.system(systemInstruction));
    }

    // Convert each GenUI message to dartantic format
    if (history != null) {
      for (final genui.ChatMessage message in history) {
        switch (message) {
          case genui.UserMessage():
            result.add(
              dartantic.ChatMessage(
                role: dartantic.ChatMessageRole.user,
                parts: _toParts(message.parts),
              ),
            );
          case genui.UserUiInteractionMessage():
            result.add(
              dartantic.ChatMessage(
                role: dartantic.ChatMessageRole.user,
                parts: _toParts(message.parts),
              ),
            );
          case genui.AiTextMessage():
            result.add(
              dartantic.ChatMessage(
                role: dartantic.ChatMessageRole.model,
                parts: _toParts(message.parts),
              ),
            );
          case genui.AiUiMessage():
            result.add(
              dartantic.ChatMessage(
                role: dartantic.ChatMessageRole.user,
                parts: _toParts(message.parts),
              ),
            );
          case genui.InternalMessage():
            result.add(dartantic.ChatMessage.system(message.text));
          case genui.ToolResponseMessage():
            result.add(
              dartantic.ChatMessage(
                role: dartantic.ChatMessageRole.user,
                parts: _toolResultPartsToDiParts(message.results),
              ),
            );
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
          if (part.data != null) {
            textParts.add('Data: ${jsonEncode(part.data)}');
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
          textParts.add(
            'ToolCall(${part.toolName}): ${jsonEncode(part.arguments)}',
          );
        case genui.ToolResultPart():
          textParts.add('ToolResult(${part.callId}): ${part.result}');
        case genui.ThinkingPart():
          textParts.add('Thinking: ${part.text}');
      }
    }
    return textParts.join('\n');
  }

  /// Converts tool response parts to a textual form for prompts.
  String _extractToolResponseText(List<genui.ToolResultPart> results) {
    return results
        .map((r) => 'ToolResult(${r.callId}): ${r.result}')
        .join('\n');
  }

  /// Converts GenUI message parts to dartantic parts.
  List<dartantic.Part> _toParts(List<genui.MessagePart> parts) {
    final converted = <dartantic.Part>[];
    for (final part in parts) {
      switch (part) {
        case genui.TextPart():
          converted.add(dartantic.TextPart(part.text));
        case genui.DataPart():
          final Map<String, Object>? data = part.data;
          if (data != null) {
            converted.add(
              dartantic.DataPart(
                utf8.encode(jsonEncode(data)),
                mimeType: 'application/json',
              ),
            );
          }
        case genui.ImagePart():
          if (part.url != null) {
            converted.add(
              dartantic.LinkPart(
                part.url!,
                mimeType: part.mimeType,
                name: null,
              ),
            );
          } else if (part.base64 != null) {
            converted.add(
              dartantic.DataPart(
                base64Decode(part.base64!),
                mimeType: part.mimeType,
              ),
            );
          } else if (part.bytes != null) {
            converted.add(
              dartantic.DataPart(part.bytes!, mimeType: part.mimeType),
            );
          } else {
            converted.add(const dartantic.TextPart('[Image data]'));
          }
        case genui.ToolCallPart():
          converted.add(
            dartantic.ToolPart.call(
              id: part.id,
              name: part.toolName,
              arguments: part.arguments,
            ),
          );
        case genui.ToolResultPart():
          converted.add(
            dartantic.ToolPart.result(
              id: part.callId,
              name: 'tool_response',
              result: _decodeMaybeJson(part.result),
            ),
          );
        case genui.ThinkingPart():
          converted.add(dartantic.TextPart('Thinking: ${part.text}'));
      }
    }
    return converted;
  }

  /// Converts GenUI message parts to dartantic parts, excluding text parts to
  /// avoid duplicate text in both prompt and attachments.
  List<dartantic.Part> _toPartsWithoutText(List<genui.MessagePart> parts) {
    final List<genui.MessagePart> filtered = parts
        .where((p) => p is! genui.TextPart)
        .toList();
    return _toParts(filtered);
  }

  /// Converts tool result parts from GenUI to dartantic ToolParts.
  List<dartantic.ToolPart> _toolResultPartsToDiParts(
    List<genui.ToolResultPart> results,
  ) {
    return results
        .map(
          (r) => dartantic.ToolPart.result(
            id: r.callId,
            name: 'tool_response',
            result: _decodeMaybeJson(r.result),
          ),
        )
        .toList();
  }

  /// Attempts to decode a JSON string; returns the original string on failure.
  dynamic _decodeMaybeJson(String input) {
    try {
      return jsonDecode(input);
    } catch (_) {
      return input;
    }
  }
}
