// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_genui_a2ui/flutter_genui_a2ui.dart';
import 'package:logging/logging.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureGenUiLogging(level: Level.ALL);
  runApp(const GenUIExampleApp());
}

/// The main application widget.
class GenUIExampleApp extends StatelessWidget {
  /// Creates a [GenUIExampleApp].
  const GenUIExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'A2UI Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ChatScreen(),
    );
  }
}

/// The main chat screen.
class ChatScreen extends StatefulWidget {
  /// Creates a [ChatScreen].
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final GenUiManager _genUiManager = GenUiManager(
    catalog: CoreCatalogItems.asCatalog(),
  );
  late final A2uiContentGenerator _contentGenerator;
  late final GenUiConversation _genUiConversation;

  @override
  void initState() {
    super.initState();
    _contentGenerator = A2uiContentGenerator(
      serverUrl: Uri.parse('http://localhost:10002'),
    );
    _genUiConversation = GenUiConversation(
      contentGenerator: _contentGenerator,
      genUiManager: _genUiManager,
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _genUiConversation.dispose();
    _genUiManager.dispose();
    _contentGenerator.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) {
    _textController.clear();
    _genUiConversation.sendRequest(UserMessage.text(text));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('A2UI Example')),
      body: Row(
        children: <Widget>[
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 200, maxWidth: 300),
            child: Column(
              children: <Widget>[
                Expanded(
                  child: ValueListenableBuilder<List<ChatMessage>>(
                    valueListenable: _genUiConversation.conversation,
                    builder: (context, messages, child) {
                      return ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        reverse: true,
                        itemBuilder: (_, int index) =>
                            _buildMessage(messages.reversed.toList()[index]),
                        itemCount: messages.length,
                      );
                    },
                  ),
                ),
                const Divider(height: 1.0),
                Container(
                  decoration: BoxDecoration(color: Theme.of(context).cardColor),
                  child: _buildTextComposer(),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: GenUiSurface(host: _genUiManager, surfaceId: 'default'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    final isUserMessage = message is UserMessage;
    var text = '';
    if (message is UserMessage) {
      text = message.text;
    } else if (message is AiTextMessage) {
      text = message.text;
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(child: Text(isUserMessage ? 'U' : 'A')),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  isUserMessage ? 'User' : 'Agent',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 5.0),
                  child: Text(text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).colorScheme.secondary),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: <Widget>[
            Flexible(
              child: TextField(
                controller: _textController,
                onSubmitted: _handleSubmitted,
                decoration: const InputDecoration.collapsed(
                  hintText: 'Send a message',
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => _handleSubmitted(_textController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
