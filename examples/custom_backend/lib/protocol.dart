// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_genui/flutter_genui.dart';

import 'api.dart';
import 'debug_utils.dart';

const _toolName = 'uiGenerationTool';

class Protocol {
  final Catalog catalog = CoreCatalogItems.asCatalog();

  Future<ParsedToolCall?> sendRequest(
    String request, {
    required String? savedResponse,
  }) async {
    final techPrompt = genUiTechPrompt([_toolName]);

    final toolCall = await Backend.sendRequest(
      tools: [
        catalogToFunctionDeclaration(
          catalog,
          _toolName,
          'Generates Flutter UI based on user requests.',
        ),
      ],
      request: '$request\n\n$techPrompt',
      savedResponse: savedResponse,
    );

    if (toolCall == null || toolCall.name != _toolName) {
      return null;
    }

    debugSaveToFileObject('toolCall', toolCall);

    return parseToolCall(toolCall, _toolName);
  }
}
