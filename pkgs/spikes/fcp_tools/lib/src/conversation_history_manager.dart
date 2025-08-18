// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'package:ai_client/ai_client.dart';
import 'package:flutter/foundation.dart';

import 'fcp_surface_manager.dart';

/// A sealed class for an entry in the conversation history.
sealed class ConversationEntry {}

/// A conversation entry that contains a chat message.
class MessageEntry extends ConversationEntry {
  /// Creates a new message entry.
  MessageEntry(this.message);

  /// The chat message.
  final ChatMessage message;
}

/// A conversation entry that contains a UI surface.
class SurfaceEntry extends ConversationEntry {
  /// Creates a new surface entry.
  SurfaceEntry(this.surfaceId);

  /// The ID of the surface.
  final String surfaceId;
}

/// Manages the history of a conversation, including chat messages and UI
/// surfaces.
///
/// This class listens to an [FcpSurfaceManager] to interleave UI surfaces
/// with the chat messages in the conversation history.
class ConversationHistoryManager with ChangeNotifier {
  /// Creates a new conversation history manager.
  ConversationHistoryManager(this._surfaceManager) {
    _surfaceManager.addListener(_surfaceManagerListener);
    _currentSurfaces = _surfaceManager.listSurfaces();
  }

  final FcpSurfaceManager _surfaceManager;
  final List<ChatMessage> _messages = [];
  final Map<String, int> _surfaceTurn = {}; // surfaceId -> message index
  List<String> _currentSurfaces = [];

  /// Adds a chat message to the history.
  void addMessage(ChatMessage message) {
    _messages.add(message);
    notifyListeners();
  }

  /// Returns the list of chat messages.
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  /// Returns the interleaved conversation history, including messages and
  /// surfaces.
  List<ConversationEntry> get history {
    final result = <ConversationEntry>[];
    final surfaceLists =
        <int, List<SurfaceEntry>>{}; // message index -> surfaces
    for (final entry in _surfaceTurn.entries) {
      surfaceLists
          .putIfAbsent(entry.value, () => [])
          .add(SurfaceEntry(entry.key));
    }

    // Add surfaces that were added before any messages.
    if (surfaceLists.containsKey(-1)) {
      result.addAll(surfaceLists[-1]!);
    }

    for (var i = 0; i < _messages.length; i++) {
      result.add(MessageEntry(_messages[i]));
      if (surfaceLists.containsKey(i)) {
        result.addAll(surfaceLists[i]!);
      }
    }

    return result;
  }

  /// Returns the chat history formatted for the AI, including the current
  /// state of all surfaces.
  List<ChatMessage> get historyForAi => List.unmodifiable(_messages);

  void _surfaceManagerListener() {
    final newSurfaces = _surfaceManager.listSurfaces();

    // Find added surfaces
    for (final surfaceId in newSurfaces) {
      if (!_currentSurfaces.contains(surfaceId)) {
        // Associate with the last message.
        _surfaceTurn[surfaceId] = _messages.isNotEmpty
            ? _messages.length - 1
            : -1;
      }
    }

    // Find removed surfaces
    for (final surfaceId in _currentSurfaces) {
      if (!newSurfaces.contains(surfaceId)) {
        _surfaceTurn.remove(surfaceId);
      }
    }

    _currentSurfaces = newSurfaces;
    notifyListeners();
  }

  @override
  void dispose() {
    _surfaceManager.removeListener(_surfaceManagerListener);
    super.dispose();
  }
}
