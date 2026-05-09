// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'ai_client.dart';
import 'chat_session.dart';
import 'message.dart';
import 'primitives/app_mode.dart';
import 'a2ui_components/climbing_gallery.dart';

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
      debugShowCheckedModeBanner: false,
      title: 'Simple Chat Controller',
      theme: ThemeData(colorScheme: colorScheme),
      darkTheme: ThemeData(
        colorScheme: colorScheme.copyWith(brightness: Brightness.dark),
      ),
      home: const ChatScreen(),
      routes: {'climbing_gallery': (context) => const ClimbingGallery()},
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.aiClient});

  final AiClient? aiClient;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

const String _defaultUserMessage =
    "I'm into rock climbing. Give me a few climbing locations around Las "
    "Vegas. I'm a beginner.";

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController(
    text: _defaultUserMessage,
  );
  final ScrollController _scrollController = ScrollController();
  late final AiClient _aiClient;
  late ChatSession _basicSession;
  late ChatSession _customSession;
  late TextOnlySession _textOnlySession;
  AppMode _appMode = AppMode.customCatalog;

  ChatBackend get _activeBackend => switch (_appMode) {
    AppMode.textOnly => _textOnlySession,
    AppMode.basicCatalog => _basicSession,
    AppMode.customCatalog => _customSession,
  };

  @override
  void initState() {
    super.initState();
    _aiClient = widget.aiClient ?? DartanticAiClient();
    _basicSession = ChatSession(aiClient: _aiClient, catalog: basicCatalog)
      ..addListener(_scrollToBottom);
    _customSession = ChatSession(aiClient: _aiClient, catalog: customCatalog)
      ..addListener(_scrollToBottom);
    _textOnlySession = TextOnlySession(aiClient: _aiClient)
      ..addListener(_scrollToBottom);
  }

  void _changeMode(AppMode mode) {
    if (mode == _appMode) return;
    setState(() {
      switch (mode) {
        case AppMode.basicCatalog:
          _basicSession.removeListener(_scrollToBottom);
          _basicSession.dispose();
          _basicSession = ChatSession(
            aiClient: _aiClient,
            catalog: basicCatalog,
          )..addListener(_scrollToBottom);
        case AppMode.customCatalog:
          _customSession.removeListener(_scrollToBottom);
          _customSession.dispose();
          _customSession = ChatSession(
            aiClient: _aiClient,
            catalog: customCatalog,
          )..addListener(_scrollToBottom);
        case AppMode.textOnly:
          _textOnlySession.removeListener(_scrollToBottom);
          _textOnlySession.dispose();
          _textOnlySession = TextOnlySession(aiClient: _aiClient)
            ..addListener(_scrollToBottom);
      }
      _appMode = mode;
      _textController.text = _defaultUserMessage;
    });
  }

  @override
  Widget build(BuildContext context) {
    final backend = _activeBackend;
    return ListenableBuilder(
      listenable: backend,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Chat (Controller + Dartantic)'),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: DropdownButton<AppMode>(
                  value: _appMode,
                  underline: const SizedBox.shrink(),
                  onChanged: (mode) {
                    if (mode == null) return;
                    _changeMode(mode);
                  },
                  items: [
                    for (final mode in AppMode.values)
                      DropdownMenuItem(
                        value: mode,
                        child: Text(mode.displayName),
                      ),
                  ],
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: backend.messages.length,
                    itemBuilder: (context, index) {
                      final Message message = backend.messages[index];
                      return ListTile(
                        title: MessageView(
                          message,
                          backend.surfaceController,
                          actionDelegate: backend.actionDelegate,
                        ),
                        tileColor: message.isUser
                            ? Colors.blue.withValues(alpha: 0.1)
                            : null,
                      );
                    },
                  ),
                ),

                if (backend.isProcessing)
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
                          enabled: !backend.isProcessing,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: backend.isProcessing ? null : _sendMessage,
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
    await _activeBackend.sendMessage(text);
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
    _basicSession.dispose();
    _customSession.dispose();
    _textOnlySession.dispose();
    _aiClient.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
