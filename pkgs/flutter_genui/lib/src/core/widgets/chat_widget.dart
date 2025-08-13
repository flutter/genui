// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../genui_manager.dart';
import '../../model/chat_box.dart';
import '../../model/chat_message.dart';
import '../../model/surface_widget.dart';
import 'chat_primitives.dart';
import '../../model/ui_models.dart';

class GenUiChat extends StatelessWidget {
  const GenUiChat({
    super.key,
    required this.genUiManager,
    this.chatBoxBuilder = defaultChatBoxBuilder,
  });

  final GenUiManager genUiManager;
  final ChatBoxBuilder chatBoxBuilder;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ChatMessage>>(
      stream: genUiManager.uiUpdates,
      initialData: const <ChatMessage>[],
      builder: (context, snapshot) {
        final messages = snapshot.data!.where((message) {
          if (genUiManager.showInternalMessages) {
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
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  index = messages.length - 1 - index; // Reverse index
                  final message = messages[index];
                  switch (message) {
                    case UserMessage():
                      if (genUiManager.userPromptBuilder != null) {
                        return genUiManager.userPromptBuilder!(
                          context,
                          message,
                        );
                      }
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
                          catalog: genUiManager.catalog,
                          surfaceId: message.surfaceId,
                          definition: UiDefinition.fromMap(message.definition),
                          onEvent: genUiManager.sendEvent,
                        ),
                      );
                    case InternalMessage():
                      return InternalMessageWidget(content: message.text);
                    case ToolResponseMessage():
                      return InternalMessageWidget(
                        content: message.results.toString(),
                      );
                  }
                },
              ),
            ),
            const SizedBox(height: 8.0),
            chatBoxBuilder(
              context,
              genUiManager.sendUserPrompt,
              genUiManager.loadingStream,
            ),
          ],
        );
      },
    );
  }
}
