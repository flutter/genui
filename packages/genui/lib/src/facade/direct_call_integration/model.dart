// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../model/a2ui_message.dart';

/// A sealed class representing a part of a tool call.
sealed class DirectCallPart {
  /// Creates a [DirectCallPart].
  const DirectCallPart();

  /// Creates a [DirectCallPart] from a JSON map.
  factory DirectCallPart.fromJson(Map<String, Object?> json) {
    switch (json['type'] as String) {
      case 'ToolCall':
        return ToolCall.fromJson(json);

      default:
        throw ArgumentError('Invalid DirectCallPart type: ${json["type"]}');
    }
  }

  /// Converts this object to a JSON representation.
  Map<String, Object?> toJson();
}

/// A tool call part.
class ToolCall extends DirectCallPart {
  /// The arguments to the tool call.
  final Object? args;

  /// The name of the tool to call.
  final String name;

  /// Creates a [ToolCall].
  const ToolCall({required this.args, required this.name});

  /// Creates a [ToolCall] from a JSON map.
  factory ToolCall.fromJson(Map<String, Object?> json) =>
      ToolCall(args: json['args'], name: json['name'] as String);

  @override
  Map<String, Object?> toJson() => {
    'type': 'ToolCall',
    'args': args,
    'name': name,
  };
}

/// Declaration to be provided to the LLM about a function/tool.
class ClientFunction {
  /// The description of the function.
  final String description;

  /// The name of the function.
  final String name;

  /// The parameters of the function.
  final Object? parameters;

  /// Creates a [ClientFunction].
  ClientFunction({
    required this.description,
    required this.name,
    this.parameters,
  });

  /// Creates a [ClientFunction] from a JSON map.
  factory ClientFunction.fromJson(Map<String, Object?> json) => ClientFunction(
    description: json['description'] as String,
    name: json['name'] as String,
    parameters: json['parameters'],
  );

  /// Converts this object to a JSON representation.
  Map<String, Object?> toJson() => {
    'description': description,
    'name': name,
    'parameters': parameters,
  };
}

/// A parsed tool call.
class ParsedToolCall {
  /// The A2UI messages from the tool call.
  final List<A2uiMessage> messages;

  /// The surface ID from the tool call.
  final String surfaceId;

  /// Creates a [ParsedToolCall].
  ParsedToolCall({required this.messages, required this.surfaceId});
}
