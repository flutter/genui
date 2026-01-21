// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../model.dart';

final class _Json {
  static const content = 'content';
  static const name = 'name';
  static const id = 'id';
  static const arguments = 'arguments';
  static const result = 'result';
}

/// A tool interaction part of a message.
@immutable
final class ToolPart extends Part {
  static const type = 'Tool';

  /// Creates a tool call part.
  const ToolPart.call({
    required this.callId,
    required this.toolName,
    required this.arguments,
  }) : kind = ToolPartKind.call,
       result = null;

  /// Creates a tool result part.
  const ToolPart.result({
    required this.callId,
    required this.toolName,
    required this.result,
  }) : kind = ToolPartKind.result,
       arguments = null;

  /// The kind of tool interaction.
  final ToolPartKind kind;

  /// The unique identifier for this tool interaction.
  final String callId;

  /// The name of the tool.
  final String toolName;

  /// The arguments for a tool call (null for results).
  final Map<String, Object?>? arguments;

  /// The result of a tool execution (null for calls).
  final Object? result;

  /// The arguments as a JSON string.
  String get argumentsRaw => arguments == null ? '' : jsonEncode(arguments);

  /// Creates a tool part from a JSON-compatible map.
  factory ToolPart.fromJson(Map<String, Object?> json) {
    final content = json[_Json.content] as Map<String, Object?>;
    if (content.containsKey(_Json.arguments)) {
      return ToolPart.call(
        callId: content[_Json.id] as String,
        toolName: content[_Json.name] as String,
        arguments: content[_Json.arguments] as Map<String, Object?>? ?? {},
      );
    } else {
      return ToolPart.result(
        callId: content[_Json.id] as String,
        toolName: content[_Json.name] as String,
        result: content[_Json.result],
      );
    }
  }

  @override
  Map<String, Object?> toJson() => {
    Part.typeKey: type,
    _Json.content: {
      _Json.id: callId,
      _Json.name: toolName,
      if (arguments != null) _Json.arguments: arguments,
      if (result != null) _Json.result: result,
    },
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;

    const deepEquality = DeepCollectionEquality();
    return other is ToolPart &&
        other.kind == kind &&
        other.callId == callId &&
        other.toolName == toolName &&
        deepEquality.equals(other.arguments, arguments) &&
        other.result == result;
  }

  @override
  int get hashCode => Object.hash(
    kind,
    callId,
    toolName,
    arguments != null ? Object.hashAll(arguments!.entries) : null,
    result,
  );

  @override
  String toString() {
    if (kind == ToolPartKind.call) {
      return 'ToolPart.call(callId: $callId, '
          'toolName: $toolName, arguments: $arguments)';
    } else {
      return 'ToolPart.result(callId: $callId, '
          'toolName: $toolName, result: $result)';
    }
  }
}

/// The kind of tool interaction.
enum ToolPartKind {
  /// A request to call a tool.
  call,

  /// The result of a tool execution.
  result,
}
