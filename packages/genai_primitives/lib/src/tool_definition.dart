// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_schema_builder/json_schema_builder.dart';

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
             'properties': <String, dynamic>{},
           });

  /// The unique name of the tool that clearly communicates its purpose.
  final String name;

  /// Used to tell the model how/when/why to use the tool. You can provide
  /// few-shot examples as a part of the description.
  final String description;

  /// Schema to parse and validate tool's input arguments. Following the [JSON
  /// Schema specification](https://json-schema.org).
  final Schema inputSchema;

  /// Converts the tool to a JSON-serializable map.
  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'inputSchema': inputSchema.value,
  };
}
