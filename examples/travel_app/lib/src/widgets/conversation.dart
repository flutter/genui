// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'package:genui/genui.dart';

typedef UserPromptBuilder =
    Widget Function(BuildContext context, ChatMessage message);

typedef UserUiInteractionBuilder =
    Widget Function(BuildContext context, ChatMessage message);

class Conversation extends StatelessWidget {
  const Conversation({
    super.key,
    required this.messages,
    required this.manager,
    this.userPromptBuilder,
    this.userUiInteractionBuilder,
    this.showInternalMessages = false,
    this.scrollController,
  });

  final List<ChatMessage> messages;
  final GenUiHost manager;
  final UserPromptBuilder? userPromptBuilder;
  final UserUiInteractionBuilder? userUiInteractionBuilder;
  final bool showInternalMessages;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final List<ChatMessage> renderedMessages = messages.where((message) {
      if (showInternalMessages) {
        return true;
      }
      final isInternal = message.role == ChatMessageRole.system;
      final bool isTool = message.parts.any(
        (p) => p is ToolPart && p.result != null,
      );
      return !isInternal && !isTool;
    }).toList();
    return ListView.builder(
      controller: scrollController,
      itemCount: renderedMessages.length,
      itemBuilder: (context, index) {
        final ChatMessage message = renderedMessages[index];
        switch (message.role) {
          case ChatMessageRole.user:
            // Check if it's an interaction (DataPart with specific mimeType? or
            // just not text?) Assuming UserUiInteractionMessage had no
            // TextPart? If it has TextPart, treat as UserMessage. If it has
            // ONLY DataPart (interaction), treat as UserUiInteractionMessage.
            // Simplified logic: If text is empty, maybe interaction?
            final String text = message.parts
                .whereType<TextPart>()
                .map((part) => part.text)
                .join('\n');

            // Check for UiInteractionPart (DataPart)
            // We need to import UiInteractionPart or check mimeType
            // But we can just check if text is empty?
            if (text.isNotEmpty) {
              return userPromptBuilder != null
                  ? userPromptBuilder!(context, message)
                  : ChatMessageView(
                      text: text,
                      icon: Icons.person,
                      alignment: MainAxisAlignment.end,
                    );
            }
            // If text empty, maybe interaction or tool result (if not hidden)
            // Tool results are usually hidden by filter above if
            // showInteralMessages=false. If showInternalMessages=true, we might
            // show them? Existing code: InternalMessageView for
            // ToolResponseMessage
            if (message.parts.any((p) => p is ToolPart)) {
              return InternalMessageView(content: message.parts.toString());
            }

            // Assume Interaction if not text and not tool?
            return userUiInteractionBuilder != null
                ? userUiInteractionBuilder!(context, message)
                : const SizedBox.shrink();

          case ChatMessageRole.model:
            // Check for UiPart
            final Iterable<DataPart> uiParts = message.parts
                .whereType<DataPart>()
                .where((p) => p.isUiPart);
            if (uiParts.isNotEmpty) {
              final UiPart uiPart = uiParts.first.asUiPart!;
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: GenUiSurface(
                  key: ValueKey(uiPart.definition.surfaceId),
                  genUiContext: manager.contextFor(uiPart.definition.surfaceId),
                ),
              );
            }

            final String text = message.parts
                .whereType<TextPart>()
                .map((part) => part.text)
                .join('\n');
            if (text.trim().isEmpty) {
              return const SizedBox.shrink();
            }
            return ChatMessageView(
              text: text,
              icon: Icons.smart_toy_outlined,
              alignment: MainAxisAlignment.start,
            );

          case ChatMessageRole.system:
            return InternalMessageView(
              content: message.parts
                  .map((p) => p is TextPart ? p.text : p.toString())
                  .join('\n'),
            );
        }
      },
    );
  }
}
