// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../engine/surface_controller.dart' show SurfaceController;
import '../engine/surface_controller.dart';
import '../interfaces/transport.dart';
import '../model/chat_message.dart';
import '../model/ui_models.dart';

/// Events emitted by [Conversation].
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
/// This class orchestrates the communication between the [SurfaceController] and
/// the [Transport]. It manages the state of the conversation,
/// including the list of active surfaces, the latest text response, and whether
/// the system is waiting for a response.
class Conversation {
  /// Creates a [Conversation].
  ///
  /// The [controller] manages the state of the UI surfaces.
  /// The [transport] handles sending and receiving messages.
  Conversation({required this.controller, required this.transport}) {
    _transportSubscription = transport.incomingMessages.listen(
      controller.handleMessage,
    );

    // Listen to transport text and emit events
    _textSubscription = transport.incomingText.listen((text) {
      _eventController.add(ConversationContentReceived(text));
      _updateState((s) => s.copyWith(latestText: text));
    });

    // Listen to controller updates and emit events
    _engineSubscription = controller.surfaceUpdates.listen((update) {
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

    // Listen for controller submissions (e.g. errors or user actions) and
    // forward them.
    _engineSubmitSubscription = controller.onSubmit.listen(sendRequest);
  }

  final SurfaceController controller;
  final Transport transport;

  final StreamController<ConversationEvent> _eventController =
      StreamController.broadcast();

  final ValueNotifier<ConversationState> _stateNotifier = ValueNotifier(
    const ConversationState(surfaces: [], latestText: '', isWaiting: false),
  );

  StreamSubscription<dynamic>? _transportSubscription;
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
      await transport.sendRequest(message);
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
    _transportSubscription?.cancel();
    _textSubscription?.cancel();
    _engineSubscription?.cancel();
    _engineSubmitSubscription?.cancel();
    _eventController.close();
    _stateNotifier.dispose();
  }
}
