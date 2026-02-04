// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/interfaces.dart';
import '../model/a2ui_message.dart';
import '../model/chat_message.dart';
import '../model/ui_models.dart';
import '../transport/gen_ui_controller.dart';

/// A high-level abstraction to manage a generative UI conversation.
///
/// This class simplifies the process of creating a generative UI by managing
/// the conversation loop.
///
/// It uses a [GenUiController] to handle the UI updates and leaves the
/// transport layer to the user via the [GenUiConversation.onSend] callback.
typedef OnSendCallback =
    Future<void> Function(ChatMessage message, Iterable<ChatMessage> history);

class GenUiConversation {
  /// Creates a new [GenUiConversation].
  ///
  /// Callbacks like [onSurfaceAdded], [onComponentsUpdated] and
  /// [onSurfaceDeleted] can be provided to react to UI changes initiated by
  /// the AI.
  GenUiConversation({
    required this.controller,
    required A2uiMessageSink messageSink,
    required GenUiHost host,
    required this.onSend,
    this.onSurfaceAdded,
    this.onComponentsUpdated,
    this.onSurfaceDeleted,
    this.onTextResponse,
    this.onError,
  }) : _host = host {
    _messageSubscription = controller.messageStream.listen((message) {
      messageSink.handleMessage(message);
    });
    _surfaceUpdateSubscription = host.surfaceUpdates.listen(
      _handleUpdateComponents,
    );
    _textSubscription = controller.textStream.listen(_handleTextResponse);
  }

  /// The [GenUiController] managing the transport.
  final GenUiController controller;
  final GenUiHost _host;

  /// The callback to call when the user sends a message.
  ///
  /// The user of this class is responsible for sending the message to their LLM
  /// and piping the response back into the [controller] via
  /// [GenUiController.addChunk].
  ///
  /// This callback should invoke the LLM with the given `message` and
  /// `history`, and stream the response back to the [controller] via
  /// [GenUiController.addChunk].
  final OnSendCallback onSend;

  /// A callback for when a new surface is added by the AI.
  final ValueChanged<SurfaceAdded>? onSurfaceAdded;

  /// A callback for when a surface is deleted by the AI.
  final ValueChanged<SurfaceRemoved>? onSurfaceDeleted;

  /// A callback for when a surface is updated by the AI.
  final ValueChanged<ComponentsUpdated>? onComponentsUpdated;

  /// A callback for when a text response is received from the AI.
  final ValueChanged<String>? onTextResponse;

  /// A callback for when an error occurs.
  final ValueChanged<Object>? onError;

  late final StreamSubscription<A2uiMessage> _messageSubscription;
  late final StreamSubscription<GenUiUpdate> _surfaceUpdateSubscription;
  late final StreamSubscription<String> _textSubscription;

  final ValueNotifier<List<ChatMessage>> _conversation =
      ValueNotifier<List<ChatMessage>>([]);
  final ValueNotifier<bool> _isProcessing = ValueNotifier<bool>(false);

  /// Handles updates to the UI components (add, update, remove).
  ///
  /// This method updates the local conversation history to reflect the changes
  /// in the UI. parameters to this method are supplied by the
  /// [GenUiController].
  void _handleUpdateComponents(GenUiUpdate update) {
    switch (update) {
      case SurfaceAdded():
        _conversation.value = [
          ..._conversation.value,
          ChatMessage.model(
            '',
            parts: [
              UiPart.create(
                definition: update.definition,
                surfaceId: update.surfaceId,
              ),
            ],
          ),
        ];
        onSurfaceAdded?.call(update);
      case ComponentsUpdated():
        final newConversation = List<ChatMessage>.from(_conversation.value);
        final int index = newConversation.lastIndexWhere(
          (m) =>
              m.role == ChatMessageRole.model &&
              m.parts.uiParts.any((p) => p.surfaceId == update.surfaceId),
        );
        final newMessage = ChatMessage.model(
          '',
          parts: [
            UiPart.create(
              definition: update.definition,
              surfaceId: update.surfaceId,
            ),
          ],
        );
        if (index != -1) {
          newConversation[index] = newMessage;
        } else {
          // This can happen if a surface is created and updated in the same
          // turn.
          newConversation.add(newMessage);
        }
        _conversation.value = newConversation;
        onComponentsUpdated?.call(update);
      case SurfaceRemoved():
        final newConversation = List<ChatMessage>.from(_conversation.value);
        newConversation.removeWhere(
          (m) =>
              m.role == ChatMessageRole.model &&
              m.parts.uiParts.any((p) => p.surfaceId == update.surfaceId),
        );
        _conversation.value = newConversation;
        onSurfaceDeleted?.call(update);
    }
  }

  /// Disposes of the resources used by this conversation.
  void dispose() {
    _messageSubscription.cancel();
    _surfaceUpdateSubscription.cancel();
    _textSubscription.cancel();
    controller.dispose();
    _isProcessing.dispose();
    _conversation.dispose();
  }

  /// The host for the UI surfaces managed by this agent.
  GenUiHost get host => _host;

  /// A [ValueListenable] that provides the current conversation history.
  ValueListenable<List<ChatMessage>> get conversation => _conversation;

  /// Whether the conversation is currently processing a request.
  ValueListenable<bool> get isProcessing => _isProcessing;

  /// Returns a [ValueNotifier] for the given [surfaceId].
  ValueListenable<UiDefinition?> surface(String surfaceId) {
    return _host.contextFor(surfaceId).definition;
  }

  /// Sends a user message to the AI.
  Future<void> sendRequest(ChatMessage message) async {
    final List<ChatMessage> history = _conversation.value;
    // Don't add to history if it's purely a UI interaction that shouldn't be
    // valid chat history.
    final bool isUiInteraction = message.parts
        .whereType<UiInteractionPart>()
        .isNotEmpty;
    if (!isUiInteraction) {
      _conversation.value = [...history, message];
    }

    // We don't construct clientCapabilities here anymore,
    // the user needs to know what they are doing when they call the LLM.
    // OR we should expose them from the controller so the user can grab them?

    _isProcessing.value = true;
    try {
      await onSend(message, history);
    } catch (e) {
      _handleError(e);
    } finally {
      _isProcessing.value = false;
    }
  }

  void _handleTextResponse(String text) {
    _conversation.value = [..._conversation.value, ChatMessage.model(text)];
    onTextResponse?.call(text);
  }

  void _handleError(Object error) {
    final errorResponseMessage = ChatMessage.model('An error occurred: $error');
    _conversation.value = [..._conversation.value, errorResponseMessage];
    onError?.call(error);
  }
}
