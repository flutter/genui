// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:genkit/genkit.dart' as genkit;
import 'package:genui_express_platform_interface/genui_express_platform_interface.dart';
import 'package:logging/logging.dart';

import 'chat_session.dart';
import 'primitives/app_mode.dart';
import 'primitives/message.dart';

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
  const ChatScreen({super.key, this.ai, this.model});

  final genkit.Genkit? ai;
  final genkit.ModelRef<dynamic>? model;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

const String _defaultUserMessage =
    """I'm into rock climbing. Give me a few climbing locations around Las Vegas. I'm a beginner.""";

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController(
    text: _defaultUserMessage,
  );
  final ScrollController _scrollController = ScrollController();
  late ChatSession _chatSession;
  AppMode _appMode = AppMode.customCatalog;
  bool? _isPlatformAvailable;
  Timer? _availabilityTimer;

  @override
  void initState() {
    super.initState();
    _checkPlatformAvailability();
    _reCreateChatSession(dispose: false);
  }

  Future<void> _checkPlatformAvailability() async {
    try {
      final bool available = await GenuiExpressPlatform.instance
          .checkAvailability();
      if (mounted) {
        setState(() {
          _isPlatformAvailable = available;
        });
        if (available) {
          _availabilityTimer?.cancel();
          _availabilityTimer = null;
        } else {
          _startAvailabilityTimer();
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isPlatformAvailable = false;
        });
        _startAvailabilityTimer();
      }
    }
  }

  void _startAvailabilityTimer() {
    if (_availabilityTimer != null) return;
    _availabilityTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkPlatformAvailability();
    });
  }

  void _reCreateChatSession({bool dispose = true}) {
    if (dispose) {
      _chatSession.removeListener(_scrollToBottom);
      _chatSession.dispose();
    }
    _chatSession = ChatSession(
      ai: widget.ai,
      model: widget.model,
      mode: _appMode,
    );
    // Add a listener to scroll to bottom when messages change.
    _chatSession.addListener(_scrollToBottom);
    _textController.text = _defaultUserMessage;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _chatSession,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Chat (Controller + Gemma 4)'),
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
                if (_isPlatformAvailable != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12.0),
                    color: _isPlatformAvailable!
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.orange.withValues(alpha: 0.15),
                    child: Row(
                      children: [
                        Icon(
                          _isPlatformAvailable!
                              ? Icons.check_circle
                              : Icons.warning,
                          color: _isPlatformAvailable!
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: Text(
                            _isPlatformAvailable!
                                ? 'Apple Intelligence Foundation Models '
                                      'are active and available!'
                                : 'Local Apple Intelligence models '
                                      'are not active. Check System Settings '
                                      '& downloads.',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _isPlatformAvailable!
                                  ? Colors.green.shade800
                                  : Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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

  void _changeMode(AppMode mode) {
    if (mode == _appMode) return;
    setState(() {
      _appMode = mode;
      _reCreateChatSession();
    });
  }

  Future<void> _sendMessage() async {
    final String text = _textController.text;
    if (text.isEmpty) return;
    _textController.clear();
    await _chatSession.sendMessage(text);
  }

  void _scrollToBottom() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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
    _availabilityTimer?.cancel();
    _chatSession.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
