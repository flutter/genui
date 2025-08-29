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

/// A high-level facade for the GenUI package.
///
/// This class simplifies the process of creating a generative UI by managing
/// the conversation loop and the interaction with the AI. It encapsulates a
/// [GenUiManager] and an [AiClient], providing a single entry point for
/// sending user requests and receiving UI updates.
class UiAgent {
  /// Creates a new [UiAgent].
  ///
  /// The [instruction] is a system prompt that guides the AI's behavior.
  ///
  /// The [catalog] defines the set of widgets available to the AI. If not
  /// provided, a default catalog of core widgets is used.
  ///
  /// Callbacks like [onSurfaceAdded] and [onSurfaceDeleted] can be provided to
  /// react to UI changes initiated by the AI.
  UiAgent(
    String instruction, {
    Catalog? catalog,
    this.onSurfaceAdded,
    this.onSurfaceDeleted,
    this.okToUpdateSurfaces = false,
    this.onWarning,
  }) : _genUiManager = GenUiManager(catalog: catalog) {
    final technicalPrompt = _technicalPrompt(
      okToUpdate: okToUpdateSurfaces,
      okToDelete: onSurfaceDeleted != null,
      okToAdd: onSurfaceAdded != null,
    );

    _aiClient = GeminiAiClient(
      systemInstruction: '$instruction\n\n$technicalPrompt',
      tools: _genUiManager.getTools(),
    );
    _aiClient.activeRequests.addListener(_onActivityUpdates);
    _aiMessageSubscription = _genUiManager.surfaceUpdates.listen(_onAiMessage);
    _userMessageSubscription = _genUiManager.userInput.listen(_onUserMessage);
  }

  /// Whether the AI is allowed to update existing surfaces.
  final bool okToUpdateSurfaces;

  final GenUiManager _genUiManager;

  late final AiClient _aiClient;

  final List<ChatMessage> _conversation = [];

  late final StreamSubscription<GenUiUpdate> _aiMessageSubscription;

  late final StreamSubscription<UserMessage> _userMessageSubscription;

  /// A callback for warnings that occur during the generative process.
  final ValueChanged<String>? onWarning;

  /// Disposes of the resources used by this agent.
  void dispose() {
    _aiClient.activeRequests.removeListener(_onActivityUpdates);
    _aiMessageSubscription.cancel();
    _userMessageSubscription.cancel();
    _genUiManager.dispose();
    _aiClient.dispose();
  }

  void _onUserMessage(UserMessage message) async {
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
    }
    final success = result!['success'] as bool? ?? false;
    if (!success) {
      final message = result['message'] as String? ?? '';
      onWarning?.call('generateContent failed with message: $message');
    }
  }

  void _onAiMessage(GenUiUpdate update) {
    if (update is SurfaceAdded) {
      if (onSurfaceAdded == null) {
        onWarning?.call(
          'AI attempted to add a surface (${update.surfaceId}), '
          'but it is not allowed to add surfaces, '
          'because onSurfaceAdded handler is not set.',
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
      if (!okToUpdateSurfaces) {
        onWarning?.call(
          'AI attempted to update a surface (${update.surfaceId}), '
          'but it is not allowed to update surfaces.',
        );
        return;
      }
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

  void _onActivityUpdates() {
    _isProcessing.value = _aiClient.activeRequests.value > 0;
  }

  /// The host for the UI surfaces managed by this agent.
  GenUiHost get host => _genUiManager;

  /// A callback for when a new surface is added by the AI.
  final ValueChanged<SurfaceAdded>? onSurfaceAdded;

  /// A callback for when a surface is deleted by the AI.
  final ValueChanged<SurfaceRemoved>? onSurfaceDeleted;

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

/// Generates the technical prompt for the AI.
///
/// In future we may want to specify which surfaces can be updated/deleted.
String _technicalPrompt({
  required bool okToUpdate,
  required bool okToDelete,
  required bool okToAdd,
}) {
  var updateInstruction = okToUpdate
      ? '''You can update existing surfaces using the `addOrUpdateSurface` tool.
      When updating a surface, if you are adding new UI to an existing surface, you should usually create a container widget (like a Column) to hold both the existing and new UI, and set that container as the new root.'''
      : 'Do not update existing surfaces.';

  var deleteInstruction = okToDelete
      ? 'Use the `deleteSurface` tool to remove UI that is no longer relevant.'
      : 'Do not delete existing surfaces.';

  var addInstruction = okToAdd
      ? 'You can add new surfaces using the `addOrUpdateSurface` tool.'
      : 'Do not add new surfaces.';

  return '''
Use the provided tools to build and manage the user interface in response to the user's requests.

$addInstruction

$updateInstruction

$deleteInstruction

When you are asking for information from the user, you should always include at least one submit button of some kind or another submitting element (like carousel) so that the user can indicate that they are done
providing information.

After you have modified the UI, be sure to use the provideFinalOutput to give
control back to the user so they can respond.
''';
}
