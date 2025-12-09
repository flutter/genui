// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'ui_models.dart';

/// A sealed class representing a part of a message.
///
/// This allows for multi-modal content in a single message.
sealed class MessagePart {}

/// A text part of a message.
final class TextPart implements MessagePart {
  /// The text content.
  final String text;

  /// Creates a [TextPart] with the given [text].
  const TextPart(this.text);
}

/// A data part that can send structured data to the model.
final class DataPart implements MessagePart {
  /// The data content.
  final Map<String, Object>? data;

  /// Creates a [DataPart] with the given [data].
  const DataPart(this.data);
}

/// An image part of a message.
///
/// Use the factory constructors to create an instance from different sources.
final class ImagePart implements MessagePart {
  /// The raw image bytes. May be null if created from a URL or Base64.
  final Uint8List? bytes;

  /// The Base64 encoded image string. May be null if created from bytes or URL.
  final String? base64;

  /// The URL of the image. May be null if created from bytes or Base64.
  final Uri? url;

  /// The MIME type of the image (e.g., 'image/jpeg', 'image/png').
  /// Required when providing image data directly.
  final String? mimeType;

  // Private constructor to enforce creation via factories.
  const ImagePart._({this.bytes, this.base64, this.url, this.mimeType});

  /// Creates an [ImagePart] from raw image bytes.
  const factory ImagePart.fromBytes(
    Uint8List bytes, {
    required String mimeType,
  }) = _ImagePartFromBytes;

  /// Creates an [ImagePart] from a Base64 encoded string.
  const factory ImagePart.fromBase64(
    String base64, {
    required String mimeType,
  }) = _ImagePartFromBase64;

  /// Creates an [ImagePart] from a URL.
  const factory ImagePart.fromUrl(Uri url) = _ImagePartFromUrl;
}

// Private implementation classes for ImagePart factories
final class _ImagePartFromBytes extends ImagePart {
  const _ImagePartFromBytes(Uint8List bytes, {required String mimeType})
    : super._(bytes: bytes, mimeType: mimeType);
}

final class _ImagePartFromBase64 extends ImagePart {
  const _ImagePartFromBase64(String base64, {required String mimeType})
    : super._(base64: base64, mimeType: mimeType);
}

final class _ImagePartFromUrl extends ImagePart {
  const _ImagePartFromUrl(Uri url) : super._(url: url);
}

/// A part representing a request from the model to call a tool.
final class ToolCallPart implements MessagePart {
  /// The name of the tool to call.
  final String toolName;

  /// The arguments for the tool, as a JSON-like map.
  final Map<String, Object?> arguments;

  /// A unique identifier for this specific tool call.
  final String id;

  /// Creates a [ToolCallPart] with the given [id], [toolName], and
  /// [arguments].
  const ToolCallPart({
    required this.id,
    required this.toolName,
    required this.arguments,
  });
}

/// A part representing the result of a tool call, to be sent back to the model.
final class ToolResultPart implements MessagePart {
  /// The ID of the this result corresponds to.
  final String callId;

  /// The result of the tool execution, often a JSON string.
  final String result;

  /// Creates a [ToolResultPart] with the given [callId] and [result].
  const ToolResultPart({required this.callId, required this.result});
}

/// A provider-specific part for "thinking" blocks.
final class ThinkingPart implements MessagePart {
  /// The reasoning content from the model.
  final String text;

  /// Creates a [ThinkingPart] with the given [text].
  const ThinkingPart(this.text);
}

/// A sealed class representing a message in the chat history.
sealed class ChatMessage {
  /// Creates a [ChatMessage].
  const ChatMessage();
}

/// A message representing an internal message
final class InternalMessage extends ChatMessage {
  /// Creates a [InternalMessage] with the given [text].
  const InternalMessage(this.text);

  /// The text of the system message.
  final String text;
}

/// A message representing a user's message.
///
/// It can be a text message, or selections in UI.
final class UserMessage extends ChatMessage {
  /// Creates a [UserMessage] with the given [parts].
  UserMessage(this.parts);

  /// Creates a [UserMessage] with the given [text].
  factory UserMessage.text(String text) => UserMessage([TextPart(text)]);

  /// The parts of the user's message.
  final List<MessagePart> parts;

  /// The text content of the user's message.
  late final String text = parts
      .whereType<TextPart>()
      .map((p) => p.text)
      .join('\n');
}

/// A message representing a user's interaction with the UI.
///
/// This is intended for internal use and is not typically displayed to the
/// user.
final class UserUiInteractionMessage extends ChatMessage {
  /// Creates a [UserUiInteractionMessage] with the given [parts].
  UserUiInteractionMessage(this.parts);

  /// Creates a [UserUiInteractionMessage] with the given [text].
  factory UserUiInteractionMessage.text(String text) =>
      UserUiInteractionMessage([TextPart(text)]);

  /// The parts of the user's message.
  final List<MessagePart> parts;

  /// The text content of the UI interaction.
  late final String text = parts
      .whereType<TextPart>()
      .map((p) => p.text)
      .join('\n');
}

/// A message representing a text response from the AI.
final class AiTextMessage extends ChatMessage {
  /// Creates a [AiTextMessage] with the given [parts].
  AiTextMessage(this.parts);

  /// Creates a [AiTextMessage] with the given [text].
  factory AiTextMessage.text(String text) => AiTextMessage([TextPart(text)]);

  /// The parts of the AI's message.
  final List<MessagePart> parts;

  /// The text content of the AI's message.
  late final String text = parts
      .whereType<TextPart>()
      .map((p) => p.text)
      .join('\n');
}

/// A message representing a response from a tool.

final class ToolResponseMessage extends ChatMessage {
  /// Creates a [ToolResponseMessage] with the given [results].

  const ToolResponseMessage(this.results);

  /// The results of the tool calls.

  final List<ToolResultPart> results;
}

/// A message representing a UI response from the AI.

final class AiUiMessage extends ChatMessage {
  /// Creates a [AiUiMessage] with the given UI [definition].

  AiUiMessage({required this.definition, String? surfaceId})
    : uiKey = UniqueKey(),

      parts = [TextPart(definition.asContextDescriptionText())],

      surfaceId =
          surfaceId ??
          ValueKey(DateTime.now().toIso8601String()).hashCode.toString();

  /// The JSON definition of the UI.

  final UiDefinition definition;

  /// A unique key for the UI widget.

  final Key uiKey;

  /// The unique ID for this UI surface.

  final String surfaceId;

  final List<MessagePart> parts;
}
