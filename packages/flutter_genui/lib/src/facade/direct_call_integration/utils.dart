// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../model/a2ui_message.dart';
import '../../model/a2ui_schemas.dart';
import '../../model/catalog.dart';
import '../../model/tools.dart';
import '../../primitives/simple_items.dart';
import 'model.dart';

/// Prompt to be provided to the LLM about how to use the UI generation tools.
String genUiTechPrompt(List<String> toolNames) {
  final toolDescription = toolNames.length > 1
      ? 'the following UI generation tools: '
            '${toolNames.map((name) => '"$name"').join(', ')}'
      : 'the UI generation tool "${toolNames.first}"';

  return '''
To show generated UI to user, use $toolDescription.
When generating UI, always provide a unique $surfaceIdKey to identify the UI surface:

* To create new UI, use a new $surfaceIdKey.
* To update existing UI, use the existing $surfaceIdKey.

Use the root component ID: 'root'.
If you want to show new UI, use a new $surfaceIdKey.
If you want to update existing UI, use the existing $surfaceIdKey.
Ensure one of the generated components has an id of 'root'.
''';
}

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

Future<ParsedToolCall> parseToolCall(ToolCall toolCall, String toolName) async {
  assert(toolCall.name == toolName);

  final messageJson = {'surfaceUpdate': toolCall.args};
  final surfaceUpdateMessage = A2uiMessage.fromJson(messageJson);

  final surfaceId = (toolCall.args as JsonMap)[surfaceIdKey] as String;

  final beginRenderingMessage = BeginRendering(
    surfaceId: surfaceId,
    root: 'root',
  );

  return ParsedToolCall(
    messages: [surfaceUpdateMessage, beginRenderingMessage],
    surfaceId: surfaceId,
  );
}

ToolCall catalogExampleToToolCall(
  JsonMap example,
  String toolName,
  String surfaceId,
) {
  final messageJson = {'surfaceUpdate': example};
  final surfaceUpdateMessage = A2uiMessage.fromJson(messageJson);

  return ToolCall(
    name: toolName,
    args: {surfaceIdKey: surfaceId, 'surfaceUpdate': surfaceUpdateMessage},
  );
}
