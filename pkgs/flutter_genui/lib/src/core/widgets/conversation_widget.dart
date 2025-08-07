// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../model/catalog.dart';
import '../../model/chat_message.dart';
import '../../model/surface_widget.dart';
import '../../model/ui_models.dart';
import '../../primitives/ui_primitives.dart';

class ConversationWidget extends StatelessWidget {
  const ConversationWidget({
    super.key,
    required this.messages,
    required this.catalog,
    required this.onEvent,
    this.systemMessageBuilder,
    this.userPromptBuilder,
    this.showInternalMessages = false,
  });

  final List<MessageData> messages;
  final void Function(Map<String, Object?> event) onEvent;
  final Catalog catalog;
  final SystemMessageBuilder? systemMessageBuilder;
  final UserPromptBuilder? userPromptBuilder;
  final bool showInternalMessages;

  @override
  Widget build(BuildContext context) {
    final renderedMessages = messages.where((message) {
      if (showInternalMessages) {
        return true;
      }
      return message is! InternalMessage && message is! UiEventMessage;
    }).toList();
    return ListView.builder(
      itemCount: renderedMessages.length,
      itemBuilder: (context, index) {
        final message = renderedMessages[index];
        return switch (message) {
          SystemMessage() =>
            systemMessageBuilder != null
                ? systemMessageBuilder!(context, message)
                : ChatMessage(
                    text: message.text,
                    icon: Icons.smart_toy_outlined,
                    alignment: MainAxisAlignment.start,
                  ),
          UserPrompt() =>
            userPromptBuilder != null
                ? userPromptBuilder!(context, message)
                : ChatMessage(
                    text: message.text,
                    icon: Icons.person,
                    alignment: MainAxisAlignment.end,
                  ),
          UiResponse() => Padding(
            padding: const EdgeInsets.all(16.0),
            child: SurfaceWidget(
              key: message.uiKey,
              catalog: catalog,
              surfaceId: message.surfaceId,
              definition: UiDefinition.fromMap(message.definition),
              onEvent: onEvent,
            ),
          ),
          InternalMessage() => InternalMessageWidget(content: message.text),
          UiEventMessage() => InternalMessageWidget(
            content: message.event.toString(),
          ),
        };
      },
    );
  }
}
