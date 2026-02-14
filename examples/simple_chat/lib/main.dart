// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'ai_client.dart';
import 'chat_session.dart';
import 'message.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Configure logging for the app.
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.blue);
    return MaterialApp(
      title: 'Simple Chat Controller',
      theme: ThemeData(colorScheme: colorScheme),
      darkTheme: ThemeData(
        colorScheme: colorScheme.copyWith(brightness: Brightness.dark),
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.aiClient});

  final AiClient? aiClient;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final ChatSession _chatSession;

  @override
  void initState() {
    super.initState();
    _chatSession = ChatSession(
      aiClient: widget.aiClient ?? DartanticAiClient(),
    );
    // Add a listener to scroll to bottom when messages change.
    _chatSession.addListener(_scrollToBottom);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _chatSession,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Chat (Controller + Dartantic)')),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _chatSession.messages.length,
                    itemBuilder: (context, index) {
                      final Message message = _chatSession.messages[index];
                      // Pass the controller as the host.
                      return ListTile(
                        title: MessageView(
                          message,
                          _chatSession.surfaceController,
                        ),
                        tileColor: message.isUser
                            ? Colors.blue.withValues(alpha: 0.1)
                            : null,
                      );
                    },
                  ),
                ),

                if (_chatSession.isProcessing)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),

                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          decoration: const InputDecoration(
                            hintText: 'Type your message...',
                          ),
                          enabled: !_chatSession.isProcessing,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _chatSession.isProcessing
                            ? null
                            : _sendMessage,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _sendMessage() async {
    final String text = _textController.text;
    if (text.isEmpty) return;
    _textController.clear();
    await _chatSession.sendMessage(text);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _chatSession.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
