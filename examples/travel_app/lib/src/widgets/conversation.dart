// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'package:flutter_genui/flutter_genui.dart';

typedef UserPromptBuilder =
    Widget Function(BuildContext context, UserMessage message);

class Conversation extends StatelessWidget {
  /// Creates a new [Conversation] widget.
  const Conversation({
    required this.messages,
    required this.manager,
    this.scrollController,
    this.emptyState,
    this.showInternalMessages = false,
    super.key,
  });

  /// The list of [ChatMessage]s to display in the conversation.
  final List<ChatMessage> messages;

  /// The [GenUiManager] that manages the generative UI surfaces.
  final GenUiManager manager;

  /// The [ScrollController] to use for the conversation view.
  final ScrollController? scrollController;

  /// The widget to display when the conversation is empty.
  final Widget? emptyState;

  /// Whether to show internal messages, such as tool responses.
  final bool showInternalMessages;

  List<ChatMessage> get renderedMessages => showInternalMessages
      ? messages
      : messages
            .where(
              (m) =>
                  !(m is InternalMessage ||
                      m is UserUiInteractionMessage ||
                      m is ToolResponseMessage),
            )
            .toList();

  @override
  Widget build(BuildContext context) {
    if (renderedMessages.isEmpty) {
      return emptyState ?? const SizedBox.shrink();
    }
    return ListView.builder(
      controller: scrollController,
      itemCount: renderedMessages.length,
      itemBuilder: (context, index) {
        final message = renderedMessages[index];
        switch (message) {
          case UserMessage():
            return ChatMessageWidget(
              text: message.parts
                  .whereType<TextPart>()
                  .map((part) => part.text)
                  .join('\n'),
              icon: Icons.person,
              alignment: MainAxisAlignment.end,
            );
          case AiTextMessage():
            final text = message.parts
                .whereType<TextPart>()
                .map((part) => part.text)
                .join('\n');
            if (text.trim().isEmpty) {
              return const SizedBox.shrink();
            }
            return ChatMessageWidget(
              text: text,
              icon: Icons.smart_toy_outlined,
              alignment: MainAxisAlignment.start,
            );
          case AiUiMessage():
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: GenUiSurface(
                key: message.uiKey,
                host: manager,
                surfaceId: message.surfaceId,
              ),
            );
          case InternalMessage():
            return InternalMessageWidget(content: message.text);
          case UserUiInteractionMessage():
            return InternalMessageWidget(
              content: message.parts
                  .whereType<TextPart>()
                  .map((part) => part.text)
                  .join('\n'),
            );
          case ToolResponseMessage():
            return InternalMessageWidget(content: message.results.toString());
        }
      },
    );
  }
}

/// A widget that displays a chat message with an icon and text.
class ChatMessageWidget extends StatelessWidget {
  /// Creates a new [ChatMessageWidget].
  const ChatMessageWidget({
    required this.text,
    required this.icon,
    required this.alignment,
    super.key,
  });

  /// The text of the message.
  final String text;

  /// The icon to display next to the message.
  final IconData icon;

  /// The alignment of the message.
  final MainAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: alignment,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(text),
            ),
          ),
        ],
      ),
    );
  }
}

/// A widget that displays an internal message.
class InternalMessageWidget extends StatelessWidget {
  /// Creates a new [InternalMessageWidget].
  const InternalMessageWidget({required this.content, super.key});

  /// The content of the message.
  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Text(
        content,
        style: const TextStyle(
          fontSize: 12.0,
          fontStyle: FontStyle.italic,
          color: Colors.black54,
        ),
      ),
    );
  }
}
