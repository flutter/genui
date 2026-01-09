// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'message_parts.dart';

final class _Json {
  static const parts = 'parts';
  static const metadata = 'metadata';
}

/// A message between participants of the interaction.
@immutable
final class Message {
  /// Creates a new message.
  ///
  /// If `parts` or `metadata` is not provided, an empty collections are used.
  ///
  /// If there is no parts of type [TextPart], the [text] property
  /// will be empty.
  ///
  /// If there are many parts of type [TextPart], the [text] property
  /// will be a concatenation of all of them.
  /// Many text parts is convenient to have to support
  /// streaming of the message.
  const Message({this.parts = const [], this.metadata = const {}});

  /// Creates text message.
  ///
  /// Converts [text] to a [TextPart] and puts it as a single member of
  /// the [parts] list.
  Message.fromText(
    String text, {
    List<Part> parts = const [],
    Map<String, Object?> metadata = const {},
  }) : this(parts: [TextPart(text), ...parts], metadata: metadata);

  /// Deserializes a message seriealized with [toJson].
  factory Message.fromJson(Map<String, Object?> json) => Message(
    parts: (json[_Json.parts] as List<Object?>)
        .map((p) => const PartConverter().convert(p as Map<String, Object?>))
        .toList(),
    metadata: (json[_Json.metadata] as Map<String, Object?>?) ?? const {},
  );

  /// Serializes the message.
  Map<String, Object?> toJson() => {
    _Json.parts: parts.map((p) => p.toJson()).toList(),
    _Json.metadata: metadata,
  };

  /// The content parts of the message.
  final List<Part> parts;

  /// Optional metadata associated with this message.
  ///
  /// This can include information like suppressed content, warnings, etc.
  final Map<String, Object?> metadata;

  /// Concatenated [TextPart] parts.
  String get text => parts.whereType<TextPart>().map((p) => p.text).join();

  /// Whether this message contains any tool calls.
  bool get hasToolCalls =>
      parts.whereType<ToolPart>().any((p) => p.kind == ToolPartKind.call);

  /// Gets all tool calls in this message.
  List<ToolPart> get toolCalls => parts
      .whereType<ToolPart>()
      .where((p) => p.kind == ToolPartKind.call)
      .toList();

  /// Whether this message contains any tool results.
  bool get hasToolResults =>
      parts.whereType<ToolPart>().any((p) => p.kind == ToolPartKind.result);

  /// Gets all tool results in this message.
  List<ToolPart> get toolResults => parts
      .whereType<ToolPart>()
      .where((p) => p.kind == ToolPartKind.result)
      .toList();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;

    final deepEquality = const DeepCollectionEquality();
    return other is Message &&
        deepEquality.equals(other.parts, parts) &&
        deepEquality.equals(other.metadata, metadata);
  }

  @override
  int get hashCode => Object.hashAll([parts, metadata]);

  @override
  String toString() => 'Message(parts: $parts, metadata: $metadata)';
}
