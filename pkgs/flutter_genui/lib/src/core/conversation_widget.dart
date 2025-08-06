// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../model/catalog.dart';
import '../model/chat_message.dart';
import '../model/surface_widget.dart';
import '../model/ui_models.dart';

typedef SystemMessageBuilder =
    Widget Function(BuildContext context, SystemMessage message);

typedef UserPromptBuilder =
    Widget Function(BuildContext context, UserPrompt message);

class ConversationWidget extends StatelessWidget {
  const ConversationWidget({
    super.key,
    required this.messages,
    required this.catalog,
    required this.onEvent,
    this.systemMessageBuilder,
    this.userPromptBuilder,
  });

  final List<ChatMessage> messages;
  final void Function(Map<String, Object?> event) onEvent;
  final Catalog catalog;
  final SystemMessageBuilder? systemMessageBuilder;
  final UserPromptBuilder? userPromptBuilder;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return switch (message) {
          SystemMessage() =>
            systemMessageBuilder != null
                ? systemMessageBuilder!(context, message)
                : Card(
                    elevation: 2.0,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    child: ListTile(
                      title: Text(message.text),
                      leading: const Icon(Icons.smart_toy_outlined),
                    ),
                  ),
          UserPrompt() =>
            userPromptBuilder != null
                ? userPromptBuilder!(context, message)
                : Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4.0,
                      horizontal: 8.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Card(
                            shape: const RoundedRectangleBorder(
                              borderRadius: const BorderRadius.only(
                                topLeft: const Radius.circular(20.0),
                                bottomLeft: const Radius.circular(20.0),
                                bottomRight: const Radius.circular(20.0),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(message.text),
                            ),
                          ),
                        ),
                      ],
                    ),
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
        };
      },
    );
  }
}
