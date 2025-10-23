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
    required this.contentGenerator,
    required this.genUiManager,
  }) {
    _a2uiSubscription = contentGenerator.a2uiMessageStream.listen(
      genUiManager.handleMessage,
    );
    _userEventSubscription = genUiManager.onSubmit.listen(
      contentGenerator.sendRequest,
    );
    _surfaceUpdateSubscription = genUiManager.surfaceUpdates.listen(
      _handleSurfaceUpdate,
    );
    _textResponseSubscription = contentGenerator.textResponseStream.listen(
      onTextResponse,
    );
  }

  final ContentGenerator contentGenerator;
  final GenUiManager genUiManager;

  /// A callback for when a new surface is added by the AI.
  final ValueChanged<SurfaceAdded>? onSurfaceAdded;

  /// A callback for when a surface is deleted by the AI.
  final ValueChanged<SurfaceRemoved>? onSurfaceDeleted;

  /// A callback for when a surface is updated by the AI.
  final ValueChanged<SurfaceUpdated>? onSurfaceUpdated;

  /// A callback for when a text response is received from the AI.
  final ValueChanged<String>? onTextResponse;

  late final StreamSubscription<A2uiMessage> _a2uiSubscription;
  late final StreamSubscription<UserMessage> _userEventSubscription;
  late final StreamSubscription<GenUiUpdate> _surfaceUpdateSubscription;
  late final StreamSubscription<String> _textResponseSubscription;

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
    contentGenerator.dispose();
    genUiManager.dispose();
  }

  /// The host for the UI surfaces managed by this agent.
  GenUiHost get host => genUiManager;

  /// A [ValueListenable] that provides the current conversation history.
  ValueListenable<List<ChatMessage>> get conversation =>
      contentGenerator.conversation;

  /// A [ValueListenable] that indicates whether the agent is currently
  /// processing a request.
  ValueListenable<bool> get isProcessing => contentGenerator.isProcessing;

  /// Returns a [ValueNotifier] for the given [surfaceId].
  ValueNotifier<UiDefinition?> surface(String surfaceId) {
    return genUiManager.surface(surfaceId);
  }

  /// Sends a user message to the AI to generate a UI response.
  Future<void> sendRequest(UserMessage message) async {
    return contentGenerator.sendRequest(message);
  }
}
