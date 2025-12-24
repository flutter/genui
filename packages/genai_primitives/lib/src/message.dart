// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'message_parts.dart';
import 'utils.dart';

final class _Json {
  static const parts = 'parts';
  static const metadata = 'metadata';
}

/// A message in a conversation between a user and a model.
@immutable
class Message {
  /// Creates a new message.
  const Message({this.parts = const [], this.metadata = const {}});

  /// Creates a new message with a single text part.
  Message.text(String text) : this(parts: [TextPart(text)]);

  /// Creates a message from a JSON-compatible map.
  factory Message.fromJson(Map<String, dynamic> json) => Message(
    parts: (json[_Json.parts] as List<dynamic>)
        .map((p) => Part.fromJson(p as Map<String, dynamic>))
        .toList(),
    metadata: (json[_Json.metadata] as Map<String, dynamic>?) ?? const {},
  );

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
    _Json.parts: parts.map((p) => p.toJson()).toList(),
    _Json.metadata: metadata,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message &&
        listEquals(other.parts, parts) &&
        mapEquals(other.metadata, metadata);
  }

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(parts), Object.hashAll(metadata.entries));

  @override
  String toString() => 'Message(parts: $parts, metadata: $metadata)';
}
