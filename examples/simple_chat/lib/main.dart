// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_genui_firebase_ai/flutter_genui_firebase_ai.dart';
import 'package:simple_chat/message.dart';
import 'firebase_options.dart';
import 'package:logging/logging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  configureGenUiLogging(level: Level.ALL);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Chat',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<MessageController> _messages = [];
  late final GenUiManager _genUiManager;
  late final UiAgent _uiAgent;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final catalog = CoreCatalogItems.asCatalog();
    _genUiManager = GenUiManager(catalog: catalog);
    final aiClient = FirebaseAiClient(
      systemInstruction:
          'You are a helpful assistant who chats with a user, '
          'giving exactly one response for each user message. '
          'Your responses should contain acknowledgment '
          'of the user message.'
          '\n\n'
          '${GenUiPromptFragments.basicChat}',
      tools: _genUiManager.getTools(),
    );
    _uiAgent = UiAgent(
      genUiManager: _genUiManager,
      aiClient: aiClient,
      onSurfaceAdded: _handleSurfaceAdded,
      onTextResponse: _onTextResponse,
      // ignore: avoid_print
      onWarning: (value) => print('Warning from UiAgent: $value'),
    );
  }

  void _handleSurfaceAdded(SurfaceAdded surface) {
    if (!mounted) return;
    setState(() {
      _messages.add(MessageController(surfaceId: surface.surfaceId));
    });
    _scrollToBottom();
  }

  void _onTextResponse(String text) {
    if (!mounted) return;
    setState(() {
      _messages.add(MessageController(text: 'AI: $text'));
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat with Firebase AI')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return ListTile(title: MessageView(message, _uiAgent.host));
                },
              ),
            ),

            ValueListenableBuilder(
              valueListenable: _uiAgent.isProcessing,
              builder: (_, isProcessing, _) {
                if (!isProcessing) return Container();
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                );
              },
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
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    final text = _textController.text;
    if (text.isEmpty) {
      return;
    }
    _textController.clear();

    setState(() {
      _messages.add(MessageController(text: 'You: $text'));
    });

    _scrollToBottom();

    unawaited(_uiAgent.sendRequest(UserMessage([TextPart(text)])));
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
    _uiAgent.dispose();
    super.dispose();
  }
}
