// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../model/a2ui_message.dart';
import '../../model/a2ui_schemas.dart';
import '../../model/catalog.dart';
import '../../primitives/simple_items.dart';
import 'model.dart';

/// Prompt to be provided to the LLM about how to use the UI generation tools.
String genUiTechPrompt(List<String> toolNames) {
  final toolDescription = toolNames.length > 1
      ? 'the following UI generation tools: '
            '${toolNames.map((name) => '"$name"').join(', ')}'
      : 'the UI generation tool "${toolNames.first}"';

  return '''
To show generated UI, use $toolDescription.
When generating UI, always provide a unique $surfaceIdKey to identify the UI surface:

* To create new UI, use a new $surfaceIdKey.
* To update existing UI, use the existing $surfaceIdKey.

Use the root component id: 'root'.
Ensure one of the generated components has an id of 'root'.
''';
}

/// Converts a [Catalog] to a [GenUiFunctionDeclaration].
GenUiFunctionDeclaration catalogToFunctionDeclaration(
  Catalog catalog,
  String toolName,
  String toolDescription,
) {
  return GenUiFunctionDeclaration(
    description: toolDescription,
    name: toolName,
    parameters: A2uiSchemas.surfaceUpdateSchema(catalog),
  );
}

/// Parses a [ToolCall] into a [ParsedToolCall].
ParsedToolCall parseToolCall(
  ToolCall toolCall,
  String toolName,
  String catalogId,
) {
  assert(toolCall.name == toolName);

  final Map<String, Object?> messageJson = {'updateComponents': toolCall.args};
  final surfaceUpdateMessage = A2uiMessage.fromJson(messageJson);

  final surfaceId = (toolCall.args as JsonMap)[surfaceIdKey] as String;

  final beginRenderingMessage = CreateSurface(
    surfaceId: surfaceId,
    catalogId: catalogId,
  );

  return ParsedToolCall(
    messages: [surfaceUpdateMessage, beginRenderingMessage],
    surfaceId: surfaceId,
  );
}

/// Converts a catalog example to a [ToolCall].
ToolCall catalogExampleToToolCall(
  JsonMap example,
  String toolName,
  String surfaceId,
) {
  final messageJson = {'updateComponents': example};
  final surfaceUpdateMessage = A2uiMessage.fromJson(messageJson);

  return ToolCall(
    name: toolName,
    args: {surfaceIdKey: surfaceId, 'updateComponents': surfaceUpdateMessage},
  );
}
