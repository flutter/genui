// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../content_generator.dart';
import '../core/genui_manager.dart';
import '../model/a2ui_message.dart';
import '../model/chat_message.dart';
import '../model/ui_models.dart';

/// A high-level abstraction to manage a generative UI conversation.
///
/// This class simplifies the process of creating a generative UI by managing
/// the conversation loop and the interaction with the AI. It encapsulates a
/// `GenUiManager` and a `ContentGenerator`, providing a single entry point for
/// sending user requests and receiving UI updates.
///
/// This is a convenience facade for the specific use case of a linear
/// conversation that can contain Gen UI surfaces.
class GenUiConversation {
  /// Creates a new [GenUiConversation].
  ///
  /// Callbacks like [onSurfaceAdded] and [onSurfaceDeleted] can be provided to
  /// react to UI changes initiated by the AI.
  GenUiConversation({
    this.onSurfaceAdded,
    this.onSurfaceUpdated,
    this.onSurfaceDeleted,
    this.onTextResponse,
    this.onError,
    required this.contentGenerator,
    required this.genUiManager,
  }) {
    _a2uiSubscription = contentGenerator.a2uiMessageStream.listen(
      genUiManager.handleMessage,
    );
    _userEventSubscription = genUiManager.onSubmit.listen(sendRequest);
    _surfaceUpdateSubscription = genUiManager.surfaceUpdates.listen(
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
  final GenUiManager genUiManager;

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
  late final StreamSubscription<UserMessage> _userEventSubscription;
  late final StreamSubscription<GenUiUpdate> _surfaceUpdateSubscription;
  late final StreamSubscription<String> _textResponseSubscription;
  late final StreamSubscription<ContentGeneratorError> _errorSubscription;

  final ValueNotifier<List<ChatMessage>> _conversation =
      ValueNotifier<List<ChatMessage>>([]);

  void _handleSurfaceUpdate(GenUiUpdate update) {
    switch (update) {
      case SurfaceAdded():
        onSurfaceAdded?.call(update);
      case SurfaceRemoved():
        onSurfaceDeleted?.call(update);
      case SurfaceUpdated():
        onSurfaceUpdated?.call(update);
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
    genUiManager.dispose();
  }

  /// The host for the UI surfaces managed by this agent.
  GenUiHost get host => genUiManager;

  /// A [ValueListenable] that provides the current conversation history.
  ValueListenable<List<ChatMessage>> get conversation => _conversation;

  /// A [ValueListenable] that indicates whether the agent is currently
  /// processing a request.
  ValueListenable<bool> get isProcessing => contentGenerator.isProcessing;

  /// Returns a [ValueNotifier] for the given [surfaceId].
  ValueNotifier<UiDefinition?> surface(String surfaceId) {
    return genUiManager.surface(surfaceId);
  }

  /// Sends a user message to the AI to generate a UI response.
  Future<void> sendRequest(UserMessage message) async {
    final history = _conversation.value;
    _conversation.value = [...history, message];
    return contentGenerator.sendRequest(message, history: history);
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
