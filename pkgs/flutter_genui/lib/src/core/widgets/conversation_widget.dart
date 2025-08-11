// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../model/catalog.dart';
import '../../model/chat_message.dart';
import '../../model/surface_widget.dart';
import '../../model/ui_models.dart';
import 'chat_primitives.dart';

typedef UserPromptBuilder =
    Widget Function(BuildContext context, UserMessage message);

class ConversationWidget extends StatelessWidget {
  const ConversationWidget({
    super.key,
    required this.messages,
    required this.catalog,
    required this.onEvent,
    this.userPromptBuilder,
    this.showInternalMessages = false,
  });

  final List<ChatMessage> messages;
  final void Function(Map<String, Object?> event) onEvent;
  final Catalog catalog;
  final UserPromptBuilder? userPromptBuilder;
  final bool showInternalMessages;

  @override
  Widget build(BuildContext context) {
    final renderedMessages = messages.where((message) {
      if (showInternalMessages) {
        return true;
      }
      return message is! InternalMessage && message is! ToolResponseMessage;
    }).toList();
    return ListView.builder(
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
          case AssistantMessage():
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
          case UiResponseMessage():
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SurfaceWidget(
                key: message.uiKey,
                catalog: catalog,
                surfaceId: message.surfaceId,
                definition: UiDefinition.fromMap(message.definition),
                onEvent: onEvent,
              ),
            );
          case InternalMessage():
            return InternalMessageWidget(content: message.text);
          case ToolResponseMessage():
            return InternalMessageWidget(content: message.results.toString());
        }
      },
    );
  }
}
