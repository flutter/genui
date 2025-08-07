// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../model/catalog.dart';
import '../../model/chat_box.dart';
import '../../model/chat_message.dart';
import '../../model/surface_widget.dart';
import '../../model/ui_models.dart';
import '../../primitives/ui_primitives.dart';

class GenUiChatController {
  final _onAiRequestSent = ValueNotifier<int>(0);
  final _onAiResponseReceived = ValueNotifier<int>(0);

  void setAiResponseReceived() {
    _onAiResponseReceived.value++;
  }

  void setAiRequestSent() {
    _onAiRequestSent.value++;
  }

  void dispose() {
    _onAiResponseReceived.dispose();
    _onAiRequestSent.dispose();
  }
}

class GenUiChat extends StatefulWidget {
  GenUiChat({
    super.key,
    required this.messages,
    required this.catalog,
    required this.onEvent,
    required this.onChatMessage,
    required this.controller,
    this.systemMessageBuilder,
    this.userPromptBuilder,
    this.showInternalMessages = false,
    this.chatBoxBuilder = defaultChatBoxBuilder,
  });

  final ChatBoxBuilder chatBoxBuilder;
  final ChatBoxCallback onChatMessage;
  final GenUiChatController controller;

  final List<MessageData> messages;
  final void Function(Map<String, Object?> event) onEvent;
  final Catalog catalog;
  final SystemMessageBuilder? systemMessageBuilder;
  final UserPromptBuilder? userPromptBuilder;
  final bool showInternalMessages;

  @override
  State<GenUiChat> createState() => _GenUiChatState();
}

class _GenUiChatState extends State<GenUiChat> {
  late final ChatBoxController _chatController = ChatBoxController(
    _onChatInput,
  );

  @override
  void initState() {
    super.initState();
    widget.controller._onAiResponseReceived.addListener(_onAiResponseReceived);
    widget.controller._onAiRequestSent.addListener(_onAiRequestSent);
  }

  void _onAiResponseReceived() {
    _chatController.setResponded();
  }

  void _onAiRequestSent() {
    _chatController.setRequested();
  }

  void _onChatInput(String input) {
    _chatController.setRequested();
    widget.onChatMessage(input);
  }

  @override
  void dispose() {
    widget.controller._onAiResponseReceived.removeListener(
      _onAiResponseReceived,
    );
    widget.controller._onAiRequestSent.removeListener(_onAiRequestSent);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = widget.messages.where((message) {
      if (widget.showInternalMessages) {
        return true;
      }
      return message is! InternalMessage && message is! UiEventMessage;
    }).toList();

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,

      children: [
        Expanded(
          child: ListView.builder(
            // Reverse the list to show the latest message at the bottom.
            reverse: true,
            itemCount: messages.length,
            itemBuilder: (context, index) {
              index = messages.length - 1 - index; // Reverse index
              final message = messages[index];
              return switch (message) {
                SystemMessage() =>
                  widget.systemMessageBuilder != null
                      ? widget.systemMessageBuilder!(context, message)
                      : ChatMessage(
                          text: message.text,
                          icon: Icons.smart_toy_outlined,
                          alignment: MainAxisAlignment.start,
                        ),
                UserPrompt() =>
                  widget.userPromptBuilder != null
                      ? widget.userPromptBuilder!(context, message)
                      : ChatMessage(
                          text: message.text,
                          icon: Icons.person,
                          alignment: MainAxisAlignment.end,
                        ),
                UiResponse() => Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SurfaceWidget(
                    key: message.uiKey,
                    catalog: widget.catalog,
                    surfaceId: message.surfaceId,
                    definition: UiDefinition.fromMap(message.definition),
                    onEvent: widget.onEvent,
                  ),
                ),
                InternalMessage() => InternalMessageWidget(
                  content: message.text,
                ),
                UiEventMessage() => InternalMessageWidget(
                  content: message.event.toString(),
                ),
              };
            },
          ),
        ),
        const SizedBox(height: 8.0),
        widget.chatBoxBuilder(_chatController, context),
      ],
    );
  }
}
