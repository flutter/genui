// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'message_parts.dart';
import 'utils.dart';

/// A message in a conversation between a user and a model.
@immutable
class ChatMessage {
  /// Creates a new message.
  const ChatMessage({
    required this.role,
    required this.parts,
    this.metadata = const {},
  });

  /// Creates a message from a JSON-compatible map.
  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    role: ChatMessageRole.values.byName(json['role'] as String),
    parts: (json['parts'] as List<dynamic>)
        .map((p) => Part.fromJson(p as Map<String, dynamic>))
        .toList(),
    metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
  );

  /// Creates a system message.
  factory ChatMessage.system(
    String text, {
    List<Part> parts = const [],
    Map<String, dynamic>? metadata,
  }) => ChatMessage(
    role: ChatMessageRole.system,
    parts: [TextPart(text), ...parts],
    metadata: metadata ?? const {},
  );

  /// Creates a user message with text.
  factory ChatMessage.user(
    String text, {
    List<Part> parts = const [],
    Map<String, dynamic>? metadata,
  }) => ChatMessage(
    role: ChatMessageRole.user,
    parts: [TextPart(text), ...parts],
    metadata: metadata ?? const {},
  );

  /// Creates a model message with text.
  factory ChatMessage.model(
    String text, {
    List<Part> parts = const [],
    Map<String, dynamic>? metadata,
  }) => ChatMessage(
    role: ChatMessageRole.model,
    parts: [TextPart(text), ...parts],
    metadata: metadata ?? const {},
  );

  /// The role of the message author.
  final ChatMessageRole role;

  /// The content parts of the message.
  final List<Part> parts;

  /// Optional metadata associated with this message.
  /// Can include information like suppressed content, warnings, etc.
  final Map<String, dynamic> metadata;

  /// Gets the text content of the message by concatenating all text parts.
  String get text => parts.whereType<TextPart>().map((p) => p.text).join();

  /// Checks if this message contains any tool calls.
  bool get hasToolCalls =>
      parts.whereType<ToolPart>().any((p) => p.kind == ToolPartKind.call);

  /// Gets all tool calls in this message.
  List<ToolPart> get toolCalls => parts
      .whereType<ToolPart>()
      .where((p) => p.kind == ToolPartKind.call)
      .toList();

  /// Checks if this message contains any tool results.
  bool get hasToolResults =>
      parts.whereType<ToolPart>().any((p) => p.kind == ToolPartKind.result);

  /// Gets all tool results in this message.
  List<ToolPart> get toolResults => parts
      .whereType<ToolPart>()
      .where((p) => p.kind == ToolPartKind.result)
      .toList();

  /// Converts the message to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'role': role.name,
    'parts': parts.map((p) => p.toJson()).toList(),
    'metadata': metadata,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage &&
        other.role == role &&
        listEquals(other.parts, parts) &&
        mapEquals(other.metadata, metadata);
  }

  @override
  int get hashCode => Object.hash(
    role,
    Object.hashAll(parts),
    Object.hashAll(metadata.entries),
  );

  @override
  String toString() =>
      'Message(role: $role, parts: $parts, metadata: $metadata)';
}

/// The role of a message author.
///
/// The role indicates the source of the message or the intended perspective.
/// For example, a system message is sent to the model to set context,
/// a user message is sent to the model, and a model message is a response
/// to the user.
enum ChatMessageRole {
  /// A message from the system that sets context or instructions for the model.
  ///
  /// System messages are typically sent to the model to define its behavior
  /// or persona ("system prompt"). They are not usually shown to the end user.
  system,

  /// A message from the end user to the model ("user prompt").
  user,

  /// A message from the model to the user ("model response").
  model,
}
