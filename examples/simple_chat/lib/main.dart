// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_genui_firebase_ai/flutter_genui_firebase_ai.dart';
import 'package:flutter_genui_dartantic/flutter_genui_dartantic.dart';
import 'package:simple_chat/message.dart';
import 'firebase_options_stub.dart';
import 'package:logging/logging.dart';

/// Configuration for which AI client to use
enum AiClientType { firebase, dartantic }

/// Global configuration - change this to switch between AI clients
///
/// To use Firebase AI: set to AiClientType.firebase
/// To use Dartantic AI: set to AiClientType.dartantic
///
/// For Dartantic AI, you'll need to set up API keys via environment variables:
/// - Google: GOOGLE_API_KEY (default provider)
/// - OpenAI: OPENAI_API_KEY
/// - Anthropic: ANTHROPIC_API_KEY
const AiClientType _aiClientType = AiClientType.dartantic;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only initialize Firebase if using Firebase AI client
  if (_aiClientType == AiClientType.firebase) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      print('Warning: Firebase initialization failed: $e');
      print('Please configure Firebase or switch to Dartantic AI client.');
    }
  }

  configureGenUiLogging(level: Level.ALL);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final title = _aiClientType == AiClientType.dartantic
        ? 'Simple Chat (Dartantic AI)'
        : 'Simple Chat (Firebase AI)';

    return MaterialApp(
      title: title,
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

    final aiClient = _createAiClient();

    _genUiConversation = GenUiConversation(
      genUiManager: _genUiManager,
      aiClient: aiClient,
      onSurfaceAdded: _handleSurfaceAdded,
      onTextResponse: _onTextResponse,
      // ignore: avoid_print
      onWarning: (value) => print('Warning from GenUiConversation: $value'),
    );
  }

  /// Creates the appropriate AI client based on the global configuration
  AiClient _createAiClient() {
    final systemInstruction =
        'You are a helpful assistant who chats with a user, '
        'giving exactly one response for each user message. '
        'Your responses should contain acknowledgment '
        'of the user message.'
        '\n\n'
        '${GenUiPromptFragments.basicChat}';

    final tools = _genUiManager.getTools();

    switch (_aiClientType) {
      case AiClientType.firebase:
        return FirebaseAiClient(
          systemInstruction: systemInstruction,
          tools: tools,
        );
      case AiClientType.dartantic:
        return DartanticAiClient(
          provider: 'google', // Options: 'openai', 'google', 'anthropic'
          model:
              'gemini-2.5-flash', // Options: 'gemini-2.5-flash', 'gemini-2.5-pro', etc.
          systemInstruction: systemInstruction,
          tools: tools,
          apiKey: const ApiKey(name: 'GEMINI_API_KEY', value: 'TODO'),
        );
    }
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
    final appBarTitle = _aiClientType == AiClientType.dartantic
        ? 'Chat with Dartantic AI'
        : 'Chat with Firebase AI';

    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
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
