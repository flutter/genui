// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class FunctionDeclaration {
  final String description;
  final String name;
  final dynamic parameters;

  FunctionDeclaration({
    required this.description,
    required this.name,
    this.parameters,
  });

  factory FunctionDeclaration.fromJson(Map<String, dynamic> json) =>
      FunctionDeclaration(
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

class UiSchemaDefinition {
  final String prompt;
  final List<FunctionDeclaration> tools;

  const UiSchemaDefinition({required this.prompt, required this.tools});

  factory UiSchemaDefinition.fromJson(Map<String, dynamic> json) =>
      UiSchemaDefinition(
        prompt: json['prompt'] as String,
        tools: (json['tools'] as List<dynamic>)
            .map((x) => FunctionDeclaration.fromJson(x as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
    'prompt': prompt,
    'tools': List<dynamic>.from(tools.map((x) => x.toJson())),
  };
}

class ToolCall {
  final dynamic args;
  final String name;

  const ToolCall({required this.args, required this.name});

  factory ToolCall.fromJson(Map<String, dynamic> json) =>
      ToolCall(args: json['args'], name: json['name'] as String);

  Map<String, dynamic> toJson() => {'args': args, 'name': name};
}
