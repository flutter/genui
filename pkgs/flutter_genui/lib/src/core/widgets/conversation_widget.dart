// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../model/catalog.dart';
import '../../model/chat_message.dart';
import '../../model/surface_widget.dart';
import '../../model/ui_models.dart';

typedef SystemMessageBuilder =
    Widget Function(BuildContext context, SystemMessage message);

typedef UserPromptBuilder =
    Widget Function(BuildContext context, UserMessage message);

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

  final List<ChatMessage> messages;
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
      return message is! InternalMessage && message is! ToolResponseMessage;
    }).toList();
    return ListView.builder(
      itemCount: renderedMessages.length,
      itemBuilder: (context, index) {
        final message = renderedMessages[index];
        return switch (message) {
          SystemMessage() =>
            systemMessageBuilder != null
                ? systemMessageBuilder!(context, message)
                : const SizedBox.shrink(),
          UserMessage() =>
            userPromptBuilder != null
                ? userPromptBuilder!(context, message)
                : _ChatMessage(
                    text: message.parts
                        .whereType<TextPart>()
                        .map((part) => part.text)
                        .join('\n'),
                    icon: Icons.person,
                    alignment: MainAxisAlignment.end,
                  ),
          AssistantMessage() => _ChatMessage(
            text: message.parts
                .whereType<TextPart>()
                .map((part) => part.text)
                .join('\n'),
            icon: Icons.smart_toy_outlined,
            alignment: MainAxisAlignment.start,
          ),
          UiResponseMessage() => Padding(
            padding: const EdgeInsets.all(16.0),
            child: SurfaceWidget(
              key: message.uiKey,
              catalog: catalog,
              surfaceId: message.surfaceId,
              definition: UiDefinition.fromMap(message.definition),
              onEvent: onEvent,
            ),
          ),
          InternalMessage() => _InternalMessageWidget(content: message.text),
          ToolResponseMessage() => _InternalMessageWidget(
            content: message.results.toString(),
          ),
        };
      },
    );
  }
}

class _InternalMessageWidget extends StatelessWidget {
  const _InternalMessageWidget({required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        color: Colors.grey.shade200,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('Internal message: $content'),
        ),
      ),
    );
  }
}

class _ChatMessage extends StatelessWidget {
  const _ChatMessage({
    required this.text,
    required this.icon,
    required this.alignment,
  });

  final String text;
  final IconData icon;
  final MainAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final isStart = alignment == MainAxisAlignment.start;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: alignment,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(
                    alignment == MainAxisAlignment.start ? 5 : 25,
                  ),
                  topRight: Radius.circular(
                    alignment == MainAxisAlignment.start ? 25 : 5,
                  ),
                  bottomLeft: const Radius.circular(25),
                  bottomRight: const Radius.circular(25),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isStart) ...[Icon(icon), const SizedBox(width: 8.0)],
                    Flexible(child: Text(text)),
                    if (!isStart) ...[const SizedBox(width: 8.0), Icon(icon)],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
