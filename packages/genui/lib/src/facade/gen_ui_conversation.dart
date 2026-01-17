// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../content_generator.dart';
import '../core/a2ui_message_processor.dart';
import '../model/a2ui_client_capabilities.dart';
import '../model/a2ui_message.dart';
import '../model/chat_message.dart';
import '../model/ui_models.dart';

/// A high-level abstraction to manage a generative UI conversation.
///
/// This class simplifies the process of creating a generative UI by managing
/// the conversation loop and the interaction with the AI. It encapsulates a
/// `A2uiMessageProcessor` and a `ContentGenerator`, providing a single entry
/// point for sending user requests and receiving UI updates.
///
/// This is a convenience facade for the specific use case of a linear
/// conversation that can contain Gen UI surfaces.
class GenUiConversation {
  /// Creates a new [GenUiConversation].
  ///
  /// Callbacks like [onSurfaceAdded], [onSurfaceUpdated] and [onSurfaceDeleted]
  /// can be provided to react to UI changes initiated by the AI.
  GenUiConversation({
    this.onSurfaceAdded,
    this.onSurfaceUpdated,
    this.onSurfaceDeleted,
    this.onTextResponse,
    this.onError,
    required this.contentGenerator,
    required this.a2uiMessageProcessor,
  }) {
    _a2uiSubscription = contentGenerator.a2uiMessageStream.listen(
      a2uiMessageProcessor.handleMessage,
    );
    _userEventSubscription = a2uiMessageProcessor.onSubmit.listen(sendRequest);
    _surfaceUpdateSubscription = a2uiMessageProcessor.surfaceUpdates.listen(
      _handleSurfaceUpdate,
    );
    _textResponseSubscription = contentGenerator.textResponseStream.listen(
      _handleTextResponse,
    );
    _errorSubscription = contentGenerator.errorStream.listen(_handleError);
  }

  /// The [ContentGenerator] for the conversation.
  final ContentGenerator contentGenerator;

  /// The manager for the UI surfaces in the conversation.
  final A2uiMessageProcessor a2uiMessageProcessor;

  /// A callback for when a new surface is added by the AI.
  final ValueChanged<SurfaceAdded>? onSurfaceAdded;

  /// A callback for when a surface is deleted by the AI.
  final ValueChanged<SurfaceRemoved>? onSurfaceDeleted;

  /// A callback for when a surface is updated by the AI.
  final ValueChanged<SurfaceUpdated>? onSurfaceUpdated;

  /// A callback for when a text response is received from the AI.
  final ValueChanged<String>? onTextResponse;

  /// A callback for when an error occurs in the content generator.
  final ValueChanged<ContentGeneratorError>? onError;

  late final StreamSubscription<A2uiMessage> _a2uiSubscription;
  late final StreamSubscription<ChatMessage> _userEventSubscription;
  late final StreamSubscription<GenUiUpdate> _surfaceUpdateSubscription;
  late final StreamSubscription<String> _textResponseSubscription;
  late final StreamSubscription<ContentGeneratorError> _errorSubscription;

  final ValueNotifier<List<ChatMessage>> _conversation =
      ValueNotifier<List<ChatMessage>>([]);

  void _handleSurfaceUpdate(GenUiUpdate update) {
    switch (update) {
      case SurfaceAdded():
        _conversation.value = [
          ..._conversation.value,
          AiUiMessage(
            definition: update.definition,
            surfaceId: update.surfaceId,
          ),
        ];
        onSurfaceAdded?.call(update);
      case SurfaceUpdated():
        final newConversation = List<ChatMessage>.from(_conversation.value);
        final int index = newConversation.lastIndexWhere(
          (m) => m is AiUiMessage && m.surfaceId == update.surfaceId,
        );
        final newMessage = AiUiMessage(
          definition: update.definition,
          surfaceId: update.surfaceId,
        );
        if (index != -1) {
          newConversation[index] = newMessage;
        } else {
          // This can happen if a surface is created and updated in the same
          // turn.
          newConversation.add(newMessage);
        }
        _conversation.value = newConversation;
        onSurfaceUpdated?.call(update);
      case SurfaceRemoved():
        final newConversation = List<ChatMessage>.from(_conversation.value);
        newConversation.removeWhere(
          (m) => m is AiUiMessage && m.surfaceId == update.surfaceId,
        );
        _conversation.value = newConversation;
        onSurfaceDeleted?.call(update);
    }
  }

  /// Disposes of the resources used by this agent.
  void dispose() {
    _a2uiSubscription.cancel();
    _userEventSubscription.cancel();
    _surfaceUpdateSubscription.cancel();
    _textResponseSubscription.cancel();
    _errorSubscription.cancel();
    contentGenerator.dispose();
    a2uiMessageProcessor.dispose();
  }

  /// The host for the UI surfaces managed by this agent.
  GenUiHost get host => a2uiMessageProcessor;

  /// A [ValueListenable] that provides the current conversation history.
  ValueListenable<List<ChatMessage>> get conversation => _conversation;

  /// A [ValueListenable] that indicates whether the agent is currently
  /// processing a request.
  ValueListenable<bool> get isProcessing => contentGenerator.isProcessing;

  /// Returns a [ValueNotifier] for the given [surfaceId].
  ValueNotifier<UiDefinition?> surface(String surfaceId) {
    return a2uiMessageProcessor.getSurfaceNotifier(surfaceId);
  }

  /// Sends a user message to the AI to generate a UI response.
  Future<void> sendRequest(ChatMessage message) async {
    final List<ChatMessage> history = _conversation.value;
    if (message is! UserUiInteractionMessage) {
      _conversation.value = [...history, message];
    }
    final clientCapabilities = A2UiClientCapabilities(
      supportedCatalogIds: a2uiMessageProcessor.catalogs
          .map((c) => c.catalogId)
          .where((id) => id != null)
          .cast<String>()
          .toList(),
    );
    return contentGenerator.sendRequest(
      message,
      history: history,
      clientCapabilities: clientCapabilities,
    );
  }

  void _handleTextResponse(String text) {
    _conversation.value = [..._conversation.value, AiTextMessage.text(text)];
    onTextResponse?.call(text);
  }

  void _handleError(ContentGeneratorError error) {
    // Add an error representation to the conversation history so the AI can see
    // that something failed.
    final errorResponseMessage = AiTextMessage.text(
      'An error occurred: ${error.error}',
    );
    _conversation.value = [..._conversation.value, errorResponseMessage];
    onError?.call(error);
  }
}
