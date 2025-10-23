// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../model/a2ui_message.dart';

sealed class Part {
  const Part();

  factory Part.fromJson(Map<String, dynamic> json) {
    switch (json['type'] as String) {
      case 'ToolCall':
        return ToolCall.fromJson(json);

      default:
        throw ArgumentError('Invalid Part type: ${json["type"]}');
    }
  }

  Map<String, dynamic> toJson();
}

class ToolCall extends Part {
  final dynamic args;
  final String name;

  const ToolCall({required this.args, required this.name});

  factory ToolCall.fromJson(Map<String, dynamic> json) =>
      ToolCall(args: json['args'], name: json['name'] as String);

  @override
  Map<String, dynamic> toJson() => {
    'type': 'ToolCall',
    'args': args,
    'name': name,
  };
}

/// Declaration to be provided to the LLM about a function/tool.
class GenUiFunctionDeclaration {
  final String description;
  final String name;
  final dynamic parameters;

  GenUiFunctionDeclaration({
    required this.description,
    required this.name,
    this.parameters,
  });

  factory GenUiFunctionDeclaration.fromJson(Map<String, dynamic> json) =>
      GenUiFunctionDeclaration(
        description: json['description'] as String,
        name: json['name'] as String,
        parameters: json['parameters'],
      );

  Map<String, dynamic> toJson() => {
    'description': description,
    'name': name,
    'parameters': parameters,
  };
}

class ParsedToolCall {
  final List<A2uiMessage> messages;
  final String surfaceId;

  ParsedToolCall({required this.messages, required this.surfaceId});
}
