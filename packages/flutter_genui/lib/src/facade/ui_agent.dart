// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter/foundation.dart';

import '../ai_client/ai_client.dart';
import '../core/genui_manager.dart';
import '../model/chat_message.dart';
import '../model/ui_models.dart';

const _maxConversationLength = 1000;

/// A high-level facade for the GenUI package.
///
/// This class simplifies the process of creating a generative UI by managing
/// the conversation loop and the interaction with the AI. It encapsulates a
/// [GenUiManager] and an [AiClient], providing a single entry point for
/// sending user requests and receiving UI updates.
class UiAgent {
  /// Creates a new [UiAgent].
  ///
  /// Callbacks like [onSurfaceAdded] and [onSurfaceDeleted] can be provided to
  /// react to UI changes initiated by the AI.
  UiAgent({
    this.onSurfaceAdded,
    this.onSurfaceDeleted,
    this.onTextResponse,
    this.onWarning,
    required GenUiManager genUiManager,
    required AiClient aiClient,
  }) : _genUiManager = genUiManager,
       _aiClient = aiClient {
    _aiClient.activeRequests.addListener(_handleActivityUpdates);
    _aiMessageSubscription = _genUiManager.surfaceUpdates.listen(
      _handleAiMessage,
    );
    _userMessageSubscription = _genUiManager.onSubmit.listen(
      _handleUserMessage,
    );
  }

  final GenUiManager _genUiManager;

  late final AiClient _aiClient;

  final List<ChatMessage> _conversation = [];

  late final StreamSubscription<GenUiUpdate> _aiMessageSubscription;

  late final StreamSubscription<UserMessage> _userMessageSubscription;

  /// A callback for warnings that occur during the generative process.
  final ValueChanged<String>? onWarning;

  /// Disposes of the resources used by this agent.
  void dispose() {
    _aiClient.activeRequests.removeListener(_handleActivityUpdates);
    _aiMessageSubscription.cancel();
    _userMessageSubscription.cancel();
    _genUiManager.dispose();
    _aiClient.dispose();
  }

  void _handleUserMessage(UserMessage message) async {
    _addMessage(message);

    final result = await _aiClient.generateContent<Map<String, Object?>>(
      _conversation,
      S.object(
        properties: {
          'success': S.boolean(
            description: 'Successfully generated a response UI.',
          ),
          'message': S.string(
            description:
                'A message about what went wrong, or a message responding to '
                'the request. Take into account any UI that has been '
                "generated, so there's no need to duplicate requests or "
                'information already present in the UI.',
          ),
        },
      ),
    );
    if (result == null) {
      onWarning?.call('No result was returned by generateContent');
      return;
    }
    final success = result['success'] as bool? ?? false;
    final messageText = result['message'] as String? ?? '';
    if (!success) {
      onWarning?.call('generateContent failed with message: $messageText');
    }
    if (messageText.isNotEmpty) {
      onTextResponse?.call(messageText);
      _addMessage(AiTextMessage.text(messageText));
    }
  }

  void _handleAiMessage(GenUiUpdate update) {
    if (update is SurfaceAdded) {
      if (onSurfaceAdded == null) {
        onWarning?.call(
          'AI attempted to add a surface (${update.surfaceId}), '
          'but onSurfaceAdded handler is not set.',
        );
        return;
      }

      final message = AiUiMessage(
        definition: update.definition,
        surfaceId: update.surfaceId,
      );
      _addMessage(message);
      onSurfaceAdded!.call(update);
    } else if (update is SurfaceRemoved) {
      if (onSurfaceDeleted == null) {
        onWarning?.call(
          'AI attempted to remove a surface (${update.surfaceId}), '
          'but onSurfaceDeleted handler is not set.',
        );
        return;
      }
      final message = AiUiMessage(
        definition: UiDefinition.fromMap({}),
        surfaceId: update.surfaceId,
      );
      _addMessage(message);
      onSurfaceDeleted!.call(update);
    } else if (update is SurfaceUpdated) {
      final message = AiUiMessage(
        definition: update.definition,
        surfaceId: update.surfaceId,
      );
      _addMessage(message);
    }
  }

  void _addMessage(ChatMessage message) {
    _conversation.add(message);
    while (_conversation.length > _maxConversationLength) {
      _conversation.removeAt(0);
    }
  }

  void _handleActivityUpdates() {
    _isProcessing.value = _aiClient.activeRequests.value > 0;
  }

  /// The host for the UI surfaces managed by this agent.
  GenUiHost get host => _genUiManager;

  /// A callback for when a new surface is added by the AI.
  final ValueChanged<SurfaceAdded>? onSurfaceAdded;

  /// A callback for when a surface is deleted by the AI.
  final ValueChanged<SurfaceRemoved>? onSurfaceDeleted;

  /// A callback for when a text response is received from the AI.
  final ValueChanged<String>? onTextResponse;

  /// A [ValueListenable] that indicates whether the agent is currently
  /// processing a request.
  ValueListenable<bool> get isProcessing => _isProcessing;
  final ValueNotifier<bool> _isProcessing = ValueNotifier(false);

  /// Returns a [ValueNotifier] for the given [surfaceId].
  ValueNotifier<UiDefinition?> surface(String surfaceId) {
    return _genUiManager.surface(surfaceId);
  }

  /// Sends a user message to the AI to generate a UI response.
  Future<void> sendRequest(UserMessage message) async {
    _addMessage(message);
    await _aiClient.generateContent(List.of(_conversation), Schema.object());
  }
}
