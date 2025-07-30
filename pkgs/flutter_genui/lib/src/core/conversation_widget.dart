import 'package:flutter/material.dart';

import '../model/catalog.dart';
import '../model/chat_message.dart';
import '../model/dynamic_ui.dart';
import '../model/ui_models.dart';

class ConversationWidget extends StatelessWidget {
  const ConversationWidget({
    super.key,
    required this.messages,
    required this.catalog,
    required this.onEvent,
  });

  final List<ChatMessage> messages;
  final void Function(Map<String, Object?> event) onEvent;
  final Catalog catalog;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return switch (message) {
          SystemMessage() => Card(
            elevation: 2.0,
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: ListTile(
              title: Text(message.text),
              leading: const Icon(Icons.smart_toy_outlined),
            ),
          ),
          TextResponse() => Card(
            elevation: 2.0,
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: ListTile(
              title: Text(message.text),
              leading: const Icon(Icons.smart_toy_outlined),
            ),
          ),
          UserPrompt() => Card(
            elevation: 2.0,
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: ListTile(
              title: Text(message.text, textAlign: TextAlign.right),
              trailing: const Icon(Icons.person),
            ),
          ),
          UiResponse() => Card(
            elevation: 2.0,
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: DynamicUi(
                key: message.uiKey,
                catalog: catalog,
                surfaceId: message.surfaceId,
                definition: UiDefinition.fromMap(message.definition),
                onEvent: onEvent,
              ),
            ),
          ),
        };
      },
    );
  }
}
