// Copyright 2026 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:genui/genui.dart';
import 'package:genui_google_generative_ai/genui_google_generative_ai.dart';
import 'package:glow/constants.dart';

class GenUiService {
  late final GenUiConversation conversation;
  late final A2uiMessageProcessor messageProcessor;

  GenUiService({
    String? apiKey,
    required String systemInstruction,
    List<CatalogItem>? additionalItems,
    void Function(SurfaceAdded)? onSurfaceAdded,
    void Function(SurfaceUpdated)? onSurfaceUpdated,
    void Function(SurfaceRemoved)? onSurfaceDeleted,
    void Function(String)? onTextResponse,
  }) {
    final mergedCatalog = additionalItems != null
        ? CoreCatalogItems.asCatalog().copyWith(additionalItems)
        : CoreCatalogItems.asCatalog();

    messageProcessor = A2uiMessageProcessor(
      catalogs: [mergedCatalog],
      // We also need to add our custom tools/actions if any.
      // For now, implicit.
    );
    conversation = GenUiConversation(
      contentGenerator: GoogleGenerativeAiContentGenerator(
        catalog: mergedCatalog,
        systemInstruction: systemInstruction,
        modelName: GlowConstants.defaultModel,
        apiKey: apiKey,
      ),
      a2uiMessageProcessor: messageProcessor,
      onSurfaceAdded: onSurfaceAdded,
      onSurfaceUpdated: onSurfaceUpdated,
      onSurfaceDeleted: onSurfaceDeleted,
      onTextResponse: onTextResponse,
    );
  }

  bool _isDisposed = false;

  void sendRequest(UserMessage message) {
    if (_isDisposed) {
      // Ignore requests after disposal to prevent "Stream closed" errors
      return;
    }
    conversation.sendRequest(message);
  }

  void dispose() {
    _isDisposed = true;
    conversation.dispose();
  }
}
