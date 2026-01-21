// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_schema_builder/json_schema_builder.dart';

final class _Json {
  static const name = 'name';
  static const description = 'description';
  static const inputSchema = 'inputSchema';
}

/// A tool that can be called by the LLM.
class ToolDefinition<TInput extends Object> {
  /// Creates a [ToolDefinition].
  ToolDefinition({
    required this.name,
    required this.description,
    Schema? inputSchema,
  }) : inputSchema =
           inputSchema ??
           Schema.fromMap({
             'type': 'object',
             'properties': <String, Object?>{},
           });

  /// Deserializes a tool from a JSON map.
  factory ToolDefinition.fromJson(Map<String, Object?> json) {
    return ToolDefinition(
      name: json[_Json.name] as String,
      description: json[_Json.description] as String,
      inputSchema: Schema.fromMap(
        json[_Json.inputSchema] as Map<String, Object?>,
      ),
    );
  }

  /// Serializes the tool to a JSON map.
  Map<String, Object?> toJson() => {
    _Json.name: name,
    _Json.description: description,
    _Json.inputSchema: inputSchema.value,
  };

  /// The unique name of the tool that clearly communicates its purpose.
  final String name;

  /// Used to tell the model how/when/why to use the tool. You can provide
  /// few-shot examples as a part of the description.
  final String description;

  /// Schema to parse and validate tool's input arguments. Following the [JSON
  /// Schema specification](https://json-schema.org).
  final Schema inputSchema;
}
