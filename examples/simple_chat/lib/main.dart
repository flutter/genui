// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ai/firebase_ai.dart' hide TextPart;
import 'package:flutter_genui/flutter_genui.dart';
import 'package:simple_chat/message.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
  // TODO: pass model from FirebaseAIService
  late final UiAgent _uiAgent = UiAgent(
    'You are a helpful assistant.',
    catalog: null,
    onSurfaceAdded: _onSurfaceAdded,
    onSurfaceRemoved: _onSurfaceRemoved,
  );
  final ScrollController _scrollController = ScrollController();

  void _onSurfaceAdded(SurfaceAdded surface) {
    _messages.add(MessageController(surfaceId: surface.surfaceId));
    setState(() {});
    _scrollToBottom();
  }

  void _onSurfaceRemoved(SurfaceRemoved surface) {
    _messages.removeWhere((message) => message.surfaceId == surface.surfaceId);
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
                  return ListTile(
                    title: MessageView(message, _uiAgent.builder),
                  );
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

  Future<void> _sendMessage() async {
    final text = _textController.text;
    if (text.isEmpty) {
      return;
    }
    _textController.clear();

    setState(() {
      _messages.add(MessageController(text: 'You: $text'));
    });

    _scrollToBottom();

    await _uiAgent.sendRequest(UserMessage([TextPart(text)]));

    setState(() {});
    _scrollToBottom();
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
}

class FirebaseAIService {
  late final GenerativeModel _model;
  late final ChatSession _chat;

  FirebaseAIService() {
    _model = FirebaseAI.googleAI().generativeModel(model: 'gemini-2.5-flash');
    _chat = _model.startChat();
  }

  Future<String> sendMessageStream(String message) async {
    final prompt = Content.text(message);
    final response = await _chat.sendMessage(prompt);
    return response.text ?? 'Sorry, I could not process that.';
  }
}
