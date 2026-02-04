// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../engine/gen_ui_engine.dart';
import '../model/chat_message.dart';
import '../model/ui_models.dart';
import '../transport/a2ui_transport_adapter.dart';

/// Events emitted by [GenUiConversation].
sealed class ConversationEvent {}

/// Fired when a new surface is added.
class ConversationSurfaceAdded extends ConversationEvent {
  ConversationSurfaceAdded(this.surfaceId, this.definition);
  final String surfaceId;
  final UiDefinition definition;
}

/// Fired when components are updated on a surface.
class ConversationComponentsUpdated extends ConversationEvent {
  ConversationComponentsUpdated(this.surfaceId, this.definition);
  final String surfaceId;
  final UiDefinition definition;
}

/// Fired when a surface is removed.
class ConversationSurfaceRemoved extends ConversationEvent {
  ConversationSurfaceRemoved(this.surfaceId);
  final String surfaceId;
}

/// Fired when new content (text) is received from the LLM.
class ConversationContentReceived extends ConversationEvent {
  ConversationContentReceived(this.text);
  final String text;
}

/// Fired when the conversation is waiting for a response.
class ConversationWaiting extends ConversationEvent {}

/// Fired when an error occurs.
class ConversationError extends ConversationEvent {
  ConversationError(this.error, [this.stackTrace]);
  final Object error;
  final StackTrace? stackTrace;
}

/// State of the conversation.
class ConversationState {
  const ConversationState({
    required this.surfaces,
    required this.latestText,
    required this.isWaiting,
  });

  /// The list of active surface IDs.
  final List<String> surfaces; // Could be richer if needed

  /// The latest text received.
  final String latestText;

  /// Whether we are waiting for a response.
  final bool isWaiting;

  ConversationState copyWith({
    List<String>? surfaces,
    String? latestText,
    bool? isWaiting,
  }) {
    return ConversationState(
      surfaces: surfaces ?? this.surfaces,
      latestText: latestText ?? this.latestText,
      isWaiting: isWaiting ?? this.isWaiting,
    );
  }
}

/// Facade for managing a GenUI conversation.
///
/// This class orchestrates the communication between the [GenUiEngine] and the
/// [A2uiTransportAdapter]. It manages the state of the conversation, including
/// the list of active surfaces, the latest text response, and whether the
/// system is waiting for a response.
class GenUiConversation {
  GenUiConversation({
    required this.engine,
    required this.adapter,
    required this.onSend,
  }) {
    // Listen to adapter messages and pipe to engine
    _adapterSubscription = adapter.messageStream.listen(engine.handleMessage);

    // Listen to adapter text and emit events
    _textSubscription = adapter.textStream.listen((text) {
      _eventController.add(ConversationContentReceived(text));
      _updateState((s) => s.copyWith(latestText: text));
    });

    // Listen to engine updates and emit events
    _engineSubscription = engine.surfaceUpdates.listen((update) {
      switch (update) {
        case SurfaceAdded(:final surfaceId, :final definition):
          _eventController.add(ConversationSurfaceAdded(surfaceId, definition));
          _updateState((s) {
            if (!s.surfaces.contains(surfaceId)) {
              return s.copyWith(surfaces: [...s.surfaces, surfaceId]);
            }
            return s;
          });
        case ComponentsUpdated(:final surfaceId, :final definition):
          _eventController.add(
            ConversationComponentsUpdated(surfaceId, definition),
          );
        case SurfaceRemoved(:final surfaceId):
          _eventController.add(ConversationSurfaceRemoved(surfaceId));
          _updateState(
            (s) => s.copyWith(
              surfaces: s.surfaces.where((id) => id != surfaceId).toList(),
            ),
          );
      }
    });

    // Listen for engine submissions (e.g. errors or user actions) and
    // forward them.
    _engineSubmitSubscription = engine.onSubmit.listen(onSend);
  }

  final GenUiEngine engine;
  final A2uiTransportAdapter adapter;
  final Future<void> Function(ChatMessage) onSend;

  final StreamController<ConversationEvent> _eventController =
      StreamController.broadcast();

  final ValueNotifier<ConversationState> _stateNotifier = ValueNotifier(
    const ConversationState(surfaces: [], latestText: '', isWaiting: false),
  );

  StreamSubscription<dynamic>? _adapterSubscription;
  StreamSubscription<dynamic>? _textSubscription;
  StreamSubscription<dynamic>? _engineSubscription;
  StreamSubscription<dynamic>? _engineSubmitSubscription;

  Stream<ConversationEvent> get events => _eventController.stream;
  ValueListenable<ConversationState> get state => _stateNotifier;

  /// Sends a request to the LLM.
  Future<void> sendRequest(ChatMessage message) async {
    _eventController.add(ConversationWaiting());
    _updateState((s) => s.copyWith(isWaiting: true));
    try {
      await onSend(message);
    } catch (e, st) {
      _eventController.add(ConversationError(e, st));
    } finally {
      _updateState((s) => s.copyWith(isWaiting: false));
    }
  }

  void _updateState(ConversationState Function(ConversationState) updater) {
    _stateNotifier.value = updater(_stateNotifier.value);
  }

  void dispose() {
    _adapterSubscription?.cancel();
    _textSubscription?.cancel();
    _engineSubscription?.cancel();
    _engineSubmitSubscription?.cancel();
    _eventController.close();
    _stateNotifier.dispose();
  }
}
