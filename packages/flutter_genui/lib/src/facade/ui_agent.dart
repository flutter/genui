// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter/foundation.dart';

import '../ai_client/ai_client.dart';
import '../ai_client/gemini_ai_client.dart';
import '../core/genui_manager.dart';
import '../model/catalog.dart';
import '../model/chat_message.dart';
import '../model/ui_models.dart';

const _maxConversationLength = 1000;

/// Generic facade for GenUi package.
class UiAgent {
  // This class limits functionality of the GenUi package.
  // with the plan to gradually extend it.
  UiAgent(
    String instruction, {
    Catalog? catalog,
    this.onSurfaceAdded,
    this.onSurfaceRemoved,
  }) : _genUiManager = GenUiManager(catalog: catalog) {
    _aiClient = GeminiAiClient(
      systemInstruction: '$instruction\n\n$_technicalPrompt',
      tools: _genUiManager.getTools(),
    );
    _aiClient.activeRequests.addListener(_onActivityUpdates);
  }

  final GenUiManager _genUiManager;
  late final AiClient _aiClient;
  final List<ChatMessage> _conversation = [];
  late final StreamSubscription<GenUiUpdate> _surfaceSubscription =
      _genUiManager.updates.listen((update) {
        if (update is SurfaceAdded) {
          onSurfaceAdded?.call(update);
        } else if (update is SurfaceRemoved) {
          onSurfaceRemoved?.call(update);
        }
      });

  void _addMessage(ChatMessage message) {
    _conversation.add(message);
    while (_conversation.length > _maxConversationLength) {
      _conversation.removeAt(0);
    }
  }

  void _onActivityUpdates() {
    _isProcessing.value = _aiClient.activeRequests.value > 0;
  }

  SurfaceBuilder get builder => _genUiManager;

  final ValueChanged<SurfaceAdded>? onSurfaceAdded;
  final ValueChanged<SurfaceRemoved>? onSurfaceRemoved;

  ValueListenable<bool> get isProcessing => _isProcessing;
  final ValueNotifier<bool> _isProcessing = ValueNotifier(false);

  ValueNotifier<UiDefinition?> surface(String surfaceId) {
    return _genUiManager.surface(surfaceId);
  }

  // TODO: listen for conversation updates from surfaces,
  // and add them to the conversation history.

  Future<void> sendRequest(UserMessage message) async {
    _addMessage(message);
    await _aiClient.generateContent(List.of(_conversation), Schema.object());
  }

  void dispose() {
    _aiClient.activeRequests.removeListener(_onActivityUpdates);
    _surfaceSubscription.cancel();
    _genUiManager.dispose();
    _aiClient.dispose();
  }
}

String _technicalPrompt = '''
Use the provided tools to build and manage the user interface in response to the user's requests. Call the `addOrUpdateSurface` tool to show new content or update existing content. Use the `deleteSurface` tool to remove UI that is no longer relevant.

When updating a surface, if you are adding new UI to an existing surface, you should usually create a container widget (like a Column) to hold both the existing and new UI, and set that container as the new root.

When you are asking for information from the user, you should always include at least one submit button of some kind or another submitting element (like carousel) so that the user can indicate that they are done
providing information.
''';
