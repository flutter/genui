// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'package:flutter_genui/flutter_genui.dart';

typedef UserPromptBuilder =
    Widget Function(BuildContext context, UserMessage message);

class Conversation extends StatelessWidget {
  const Conversation({
    super.key,
    required this.messages,
    required this.manager,
    this.userPromptBuilder,
    this.showInternalMessages = false,
    this.scrollController,
  });

  final List<ChatMessage> messages;
  final GenUiManager manager;
  final UserPromptBuilder? userPromptBuilder;
  final bool showInternalMessages;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final renderedMessages = messages.where((message) {
      if (showInternalMessages) {
        return true;
      }
      return message is! InternalMessage &&
          message is! ToolResponseMessage &&
          message is! UserUiInteractionMessage;
    }).toList();
    return ListView.builder(
      controller: scrollController,
      itemCount: renderedMessages.length,
      itemBuilder: (context, index) {
        final message = renderedMessages[index];
        switch (message) {
          case UserMessage():
            return userPromptBuilder != null
                ? userPromptBuilder!(context, message)
                : ChatMessageWidget(
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
