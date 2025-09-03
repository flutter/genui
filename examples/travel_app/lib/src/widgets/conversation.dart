// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

import '../turn.dart';
import 'ai_response.dart';
import 'ui_response.dart';
import 'user_prompt.dart';

/// A widget that displays a conversation between a user and an AI.
class Conversation extends StatelessWidget {
  /// Creates a new [Conversation] widget.
  const Conversation({
    required this.messages,
    required this.manager,
    required this.onEvent,
    this.scrollController,
    super.key,
  });

  /// The list of messages in the conversation.
  final List<Turn> messages;

  /// The [GenUiManager] that manages the UI surfaces.
  final GenUiManager manager;

  /// A callback that is called when a UI event occurs.
  final void Function(UiEvent) onEvent;

  /// The scroll controller for the conversation view.
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return switch (message) {
          UserTurn() => UserPrompt(message: message.text),
          UserUiInteractionTurn() => UserPrompt(message: message.text),
          GenUiTurn() => UiResponse(
              surfaceId: message.surfaceId,
              manager: manager,
              onEvent: onEvent,
            ),
          AiTextTurn() => AiResponse(message: message.text),
        };
      },
    );
  }
}
