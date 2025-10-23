// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_genui/flutter_genui.dart';

import 'debug_utils.dart';
import 'gemini_client.dart';

class UiSchemaDefinition {
  final String prompt;
  final List<GenUiFunctionDeclaration> tools;

  const UiSchemaDefinition({required this.prompt, required this.tools});

  factory UiSchemaDefinition.fromJson(Map<String, dynamic> json) =>
      UiSchemaDefinition(
        prompt: json['prompt'] as String,
        tools: (json['tools'] as List<dynamic>)
            .map(
              (x) =>
                  GenUiFunctionDeclaration.fromJson(x as Map<String, dynamic>),
            )
            .toList(),
      );

  Map<String, dynamic> toJson() => {
    'type': 'UiSchemaDefinition',
    'prompt': prompt,
    'tools': List<dynamic>.from(tools.map((x) => x.toJson())),
  };
}

class Backend {
  Backend(this.schema);

  final UiSchemaDefinition schema;

  Future<ParsedToolCall?> sendRequest(
    String request, {
    required String? savedResponse,
  }) async {
    final toolCall = await GeminiClient.sendRequest(
      tools: schema.tools,
      request: '${schema.prompt}\n\nUser request:\n$request',
      savedResponse: savedResponse,
    );

    if (toolCall == null) return null;

    if (!schema.tools.map((e) => e.name).contains(toolCall.name)) {
      throw Exception(
        'Received unknown tool call: ${toolCall.name}'
        'Expected one of: ${schema.tools.map((e) => e.name).toList()}',
      );
    }

    debugSaveToFileObject('toolCall', toolCall);

    return parseToolCall(toolCall, toolCall.name);
  }
}
