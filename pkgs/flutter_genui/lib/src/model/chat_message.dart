// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'ui_models.dart';

typedef SystemMessageBuilder =
    Widget Function(BuildContext context, SystemMessage message);

typedef UserPromptBuilder =
    Widget Function(BuildContext context, UserPrompt message);

/// A sealed class representing a message in the chat history.
sealed class ChatMessage {
  const ChatMessage();
}

/// A message representing a system message.
class SystemMessage extends ChatMessage {
  /// Creates a [SystemMessage] with the given [text].
  const SystemMessage({required this.text});

  /// The text of the system message.
  final String text;
}

/// A message representing an internal message
class InternalMessage extends ChatMessage {
  /// Creates a [InternalMessage] with the given [text].
  const InternalMessage(this.text);

  /// The text of the system message.
  final String text;
}

/// A message representing a user's text prompt.
class UserPrompt extends ChatMessage {
  /// Creates a [UserPrompt] with the given [text].
  const UserPrompt({required this.text});

  /// The text of the user's prompt.
  final String text;
}

/// A message representing a UI response from the AI.
class UiResponse extends ChatMessage {
  /// Creates a [UiResponse] with the given UI [definition].
  UiResponse({required this.definition, String? surfaceId})
    : uiKey = UniqueKey(),
      surfaceId =
          surfaceId ??
          ValueKey(DateTime.now().toIso8601String()).hashCode.toString();

  /// The JSON definition of the UI.
  final Map<String, Object?> definition;

  /// A unique key for the UI widget.
  final Key uiKey;

  /// The unique ID for this UI surface.
  final String surfaceId;
}

/// A message representing a UI event from the user.
class UiEventMessage extends ChatMessage {
  /// Creates a [UiEventMessage] with the given [event].
  const UiEventMessage({required this.event});

  /// The UI event that was triggered.
  final UiEvent event;
}
