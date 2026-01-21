// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'parts/items.dart';
import 'parts/model.dart';
import 'parts/parts.dart';

final class _Json {
  static const parts = 'parts';
  static const role = 'role';
  static const metadata = 'metadata';
}

/// A chat message.
@immutable
final class ChatMessage {
  /// Creates a new message.
  ///
  /// If `parts` or `metadata` is not provided, an empty collections are used.
  ///
  /// If there are no parts of type [TextPart], the [text] property
  /// will be empty.
  ///
  /// If there is more than one part of type [TextPart], the [text] property
  /// will be a concatenation of all of them.
  const ChatMessage({
    required this.role,
    this.parts = const Parts([]),
    this.metadata = const {},
  });

  /// Creates a system message.
  ///
  /// If [text] is not empty, converts it to a [TextPart] and puts it as a
  /// first member of the [parts] list.
  ///
  /// [parts] may contain any type of [Part], including additional
  /// instances of [TextPart].
  ChatMessage.system(
    String text, {
    List<Part> parts = const [],
    Map<String, Object?> metadata = const {},
  }) : this(
         role: ChatMessageRole.system,
         parts: Parts.fromText(text, parts: parts),
         metadata: metadata,
       );

  /// Creates a user message.
  ///
  /// If [text] is not empty, converts it to a [TextPart] and puts it as a
  /// first member of the [parts] list.
  ///
  /// [parts] may contain any type of [Part], including additional
  /// instances of [TextPart].
  ChatMessage.user(
    String text, {
    List<Part> parts = const [],
    Map<String, Object?> metadata = const {},
  }) : this(
         role: ChatMessageRole.user,
         parts: Parts.fromText(text, parts: parts),
         metadata: metadata,
       );

  /// Creates a model message.
  ///
  /// If [text] is not empty, converts it to a [TextPart] and puts it as a
  /// first member of the [parts] list.
  ///
  /// [parts] may contain any type of [Part], including additional
  /// instances of [TextPart].
  ChatMessage.model(
    String text, {
    List<Part> parts = const [],
    Map<String, Object?> metadata = const {},
  }) : this(
         role: ChatMessageRole.model,
         parts: Parts.fromText(text, parts: parts),
         metadata: metadata,
       );

  /// Deserializes a message.
  ///
  /// The message is compatible with [toJson].
  ///
  /// The [converterRegistry] parameter is a map of part types to converters.
  /// If the registry is not provided, [defaultPartConverterRegistry] is used.
  ///
  /// If you do not need to deserialize custom part types, you can omit the
  /// [converterRegistry] parameter.
  factory ChatMessage.fromJson(
    Map<String, Object?> json, {
    Map<String, JsonToPartConverter> converterRegistry =
        defaultPartConverterRegistry,
  }) => ChatMessage(
    role: ChatMessageRole.values.byName(json[_Json.role] as String),
    parts: Parts.fromJson(
      json[_Json.parts] as List<Object?>,
      converterRegistry: converterRegistry,
    ),
    metadata: (json[_Json.metadata] as Map<String, Object?>?) ?? const {},
  );

  /// Serializes the message to JSON.
  Map<String, Object?> toJson() => {
    _Json.parts: parts.toJson(),
    _Json.metadata: metadata,
    _Json.role: role.name,
  };

  /// The role of the message author.
  final ChatMessageRole role;

  /// The content parts of the message.
  final Parts parts;

  /// Optional metadata associated with this message.
  ///
  /// This can include information like suppressed content, warnings, etc.
  final Map<String, Object?> metadata;

  /// Concatenated [TextPart] parts.
  String get text => parts.text;

  /// Whether this message contains any tool calls.
  bool get hasToolCalls => parts.toolCalls.isNotEmpty;

  /// Gets all tool calls in this message.
  List<ToolPart> get toolCalls => parts.toolCalls;

  /// Whether this message contains any tool results.
  bool get hasToolResults => parts.toolResults.isNotEmpty;

  /// Gets all tool results in this message.
  List<ToolPart> get toolResults => parts.toolResults;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;

    const deepEquality = DeepCollectionEquality();
    return other is ChatMessage &&
        deepEquality.equals(other.parts, parts) &&
        deepEquality.equals(other.metadata, metadata);
  }

  @override
  int get hashCode => Object.hashAll([parts, metadata]);

  @override
  String toString() => 'Message(parts: $parts, metadata: $metadata)';
}

/// The role of a message author.
///
/// The role indicates the source of the message or the intended perspective.
/// For example, a system message is sent to the model to set context,
/// a user message is sent to the model as a request,
/// and a model message is a response to the user request.
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
