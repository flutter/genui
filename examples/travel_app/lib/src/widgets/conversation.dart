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
  final SurfaceHost manager;
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
            final bool hasUiInteraction = message.parts.any(
              (p) => p.isUiInteractionPart,
            );
            final String text = message.parts
                .whereType<TextPart>()
                .map((part) => part.text)
                .join('\n');

            if (text.isNotEmpty) {
              return userPromptBuilder != null
                  ? userPromptBuilder!(context, message)
                  : ChatMessageView(
                      text: text,
                      icon: Icons.person,
                      alignment: MainAxisAlignment.end,
                    );
            }
            if (message.parts.any((p) => p is ToolPart)) {
              return InternalMessageView(content: message.parts.toString());
            }

            if (hasUiInteraction) {
              return userUiInteractionBuilder != null
                  ? userUiInteractionBuilder!(context, message)
                  : const SizedBox.shrink();
            }

            return const SizedBox.shrink();

          case ChatMessageRole.model:
            final Iterable<DataPart> uiParts = message.parts
                .whereType<DataPart>()
                .where((p) => p.isUiPart);
            if (uiParts.isNotEmpty) {
              final UiPart uiPart = uiParts.first.asUiPart!;
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Surface(
                  key: ValueKey(uiPart.definition.surfaceId),
                  surfaceContext: manager.contextFor(
                    uiPart.definition.surfaceId,
                  ),
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
