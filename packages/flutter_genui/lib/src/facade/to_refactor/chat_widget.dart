// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/genui_manager.dart';

import '../../core/widgets/chat_primitives.dart';
import '../../model/chat_box.dart';
import '../../model/chat_message.dart';
import '../genui_surface.dart';

class GenUiChatController {
  GenUiChatController({required this.manager}) {
    _conversation.value = manager.surfaces.entries.map((entry) {
      final surfaceId = entry.key;
      final definition = entry.value.value;
      _surfaceIds.add(surfaceId);
      return AiUiMessage(definition: definition!, surfaceId: surfaceId);
    }).toList();
    _updateSubscription = manager.surfaceUpdates.listen(_onUpdate);
  }

  late final StreamSubscription<GenUiUpdate> _updateSubscription;
  final GenUiManager manager;
  final _onAiRequestSent = ValueNotifier<int>(0);
  final _onAiResponseReceived = ValueNotifier<int>(0);
  final _conversation = ValueNotifier<List<ChatMessage>>([]);
  final _surfaceIds = <String>[];

  ValueNotifier<List<ChatMessage>> get conversation => _conversation;

  void addMessage(ChatMessage message) {
    _conversation.value = [..._conversation.value, message];
  }

  void _onUpdate(GenUiUpdate update) {
    final currentConversation = _conversation.value;
    switch (update) {
      case SurfaceAdded(:final surfaceId, :final definition):
        if (!_surfaceIds.contains(surfaceId)) {
          _surfaceIds.add(surfaceId);
          _conversation.value = [
            ...currentConversation,
            AiUiMessage(definition: definition, surfaceId: surfaceId),
          ];
        }
      case SurfaceRemoved(:final surfaceId):
        _surfaceIds.remove(surfaceId);
        _conversation.value = currentConversation
            .where((m) => !(m is AiUiMessage && m.surfaceId == surfaceId))
            .toList();
      case SurfaceUpdated(:final surfaceId, :final definition):
        final index = currentConversation.lastIndexWhere(
          (m) => m is AiUiMessage && m.surfaceId == surfaceId,
        );
        if (index != -1) {
          final newConversation = [...currentConversation];
          newConversation[index] = AiUiMessage(
            definition: definition,
            surfaceId: surfaceId,
          );
          _conversation.value = newConversation;
        }
    }
  }

  void setAiResponseReceived() {
    _onAiResponseReceived.value++;
  }

  void setAiRequestSent() {
    _onAiRequestSent.value++;
  }

  void dispose() {
    _updateSubscription.cancel();
    _onAiResponseReceived.dispose();
    _onAiRequestSent.dispose();
    _conversation.dispose();
  }
}

class GenUiChat extends StatefulWidget {
  const GenUiChat({
    super.key,
    required this.onEvent,
    required this.onChatMessage,
    required this.controller,
    this.showInternalMessages = false,
    this.chatBoxBuilder = defaultChatBoxBuilder,
  });

  final ChatBoxBuilder chatBoxBuilder;
  final ChatBoxCallback onChatMessage;
  final GenUiChatController controller;

  final UiEventCallback onEvent;
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
    return ValueListenableBuilder<List<ChatMessage>>(
      valueListenable: widget.controller.conversation,
      builder: (context, messages, child) {
        final filteredMessages = messages.where((message) {
          if (widget.showInternalMessages) {
            return true;
          }
          return message is! InternalMessage && message is! ToolResponseMessage;
        }).toList();

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: ListView.builder(
                // Reverse the list to show the latest message at the bottom.
                reverse: true,
                itemCount: filteredMessages.length,
                itemBuilder: (context, index) {
                  index = filteredMessages.length - 1 - index; // Reverse index
                  final message = filteredMessages[index];
                  switch (message) {
                    case UserMessage():
                      final text = message.parts
                          .whereType<TextPart>()
                          .map<String>((part) => part.text)
                          .join('\n');
                      if (text.trim().isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return ChatMessageWidget(
                        text: text,
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
                          host: widget.controller.manager,
                          surfaceId: message.surfaceId,
                          onEvent: widget.onEvent,
                        ),
                      );
                    case InternalMessage():
                      return const SizedBox.shrink();
                    case ToolResponseMessage():
                      return const SizedBox.shrink();
                  }
                },
              ),
            ),
            const SizedBox(height: 8.0),
            widget.chatBoxBuilder(_chatController, context),
          ],
        );
      },
    );
  }
}
