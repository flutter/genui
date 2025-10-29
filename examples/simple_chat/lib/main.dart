// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_genui_firebase_ai/flutter_genui_firebase_ai.dart';
import 'package:flutter_genui_google_generative_ai/flutter_genui_google_generative_ai.dart';
import 'package:simple_chat/message.dart';
import 'firebase_options_stub.dart';
import 'package:logging/logging.dart';

/// Enum for selecting which AI backend to use.
enum AiBackend {
  /// Use Firebase AI
  firebase,

  /// Use Google Generative AI
  google,
}

/// Configuration for which AI backend to use.
/// Change this value to switch between backends.
const AiBackend AI_BACKEND = AiBackend.google;

/// API key for Google Generative AI (only needed if using google backend).
/// Replace with your actual API key from https://aistudio.google.com/app/apikey
const String googleApiKey = 'REPLACE ME';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only initialize Firebase if using firebase backend
  if (AI_BACKEND == AiBackend.firebase) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

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
  late final GenUiConversation _genUiConversation;
  late final GenUiManager _genUiManager;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final catalog = CoreCatalogItems.asCatalog();
    _genUiManager = GenUiManager(catalog: catalog);

    final systemInstruction =
        'You are a helpful assistant who chats with a user, '
        'giving exactly one response for each user message. '
        'Your responses should contain acknowledgment '
        'of the user message.'
        '\n\n'
        '${GenUiPromptFragments.basicChat}';

    // Create the appropriate content generator based on configuration
    final ContentGenerator contentGenerator = switch (AI_BACKEND) {
      AiBackend.google => () {
        if (googleApiKey.isEmpty) {
          throw Exception(
            'Google API key is required when using google backend. '
            'Set GOOGLE_API_KEY environment variable.',
          );
        }
        return GoogleGenerativeAiContentGenerator(
          catalog: catalog,
          systemInstruction: systemInstruction,
          apiKey: googleApiKey,
        );
      }(),
      AiBackend.firebase => FirebaseAiContentGenerator(
        catalog: catalog,
        systemInstruction: systemInstruction,
      ),
    };

    _genUiConversation = GenUiConversation(
      genUiManager: _genUiManager,
      contentGenerator: contentGenerator,
      onSurfaceAdded: _handleSurfaceAdded,
      onTextResponse: _onTextResponse,
      onError: (error) {
        genUiLogger.severe(
          'Error from content generator',
          error.error,
          error.stackTrace,
        );
      },
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
    final title = switch (AI_BACKEND) {
      AiBackend.google => 'Chat with Google Generative AI',
      AiBackend.firebase => 'Chat with Firebase AI',
    };

    return Scaffold(
      appBar: AppBar(title: Text(title)),
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
                    title: MessageView(message, _genUiConversation.host),
                  );
                },
              ),
            ),

            ValueListenableBuilder(
              valueListenable: _genUiConversation.isProcessing,
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

    unawaited(_genUiConversation.sendRequest(UserMessage([TextPart(text)])));
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
    _genUiConversation.dispose();
    super.dispose();
  }
}
