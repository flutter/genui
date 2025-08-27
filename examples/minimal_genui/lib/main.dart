// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:logging/logging.dart';

import 'firebase_options.dart';

const _chatPrompt = '''
You are a helpful assistant who figures out what the user wants to do and then helps suggest options so they can develop a plan and find relevant information.

The user will ask questions, and you will respond by generating appropriate UI elements. If the user question is too generic, you will first elicit more information to understand the user's request better, then you will start displaying information and the user's plans.

Use the provided tools to build and manage the user interface in response to the user's requests. Call the `addOrUpdateSurface` tool to show new content or update existing content. Use the `deleteSurface` tool to remove UI that is no longer relevant.

When you are asking for information from the user, you should always include at least one submit button of some kind or another submitting element (like carousel) so that the user can indicate that they are done
providing information.

When updating a surface, if you are adding new UI to an existing surface, you should usually create a container widget (like a Column) to hold both the existing and new UI, and set that container as the new root.
''';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  configureGenUiLogging(level: Level.ALL);
  runApp(const MyApp());
}

const title = 'Minimal GenUI Example';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final GenUiManager _genUiManager;
  late final GeminiAiClient _aiClient;
  late final GenUiChatController _chatController;

  @override
  void initState() {
    super.initState();
    _genUiManager = GenUiManager();
    _chatController = GenUiChatController(manager: _genUiManager);
    _aiClient = GeminiAiClient(
      systemInstruction: _chatPrompt,
      tools: _genUiManager.getTools(),
    );
  }

  @override
  void dispose() {
    _genUiManager.dispose();
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _triggerInference() async {
    _chatController.setAiRequestSent();
    try {
      final response = await _aiClient.generateText(
        List.of(_chatController.conversation.value),
      );
      _chatController.addMessage(AiMessage.text(response));
    } finally {
      _chatController.setAiResponseReceived();
    }
  }

  void _handleUiEvent(UiEvent event) {
    if (!event.isAction) return;

    _chatController.addMessage(
      UserMessage.text(
        'The user triggered the "${event.eventType}" event on widget '
        '"${event.widgetId}" with the value: ${event.value}.',
      ),
    );
    unawaited(_triggerInference());
  }

  void _sendPrompt(String text) {
    _chatController.addMessage(UserMessage.text(text));
    unawaited(_triggerInference());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GenUiChat(
          onEvent: _handleUiEvent,
          onChatMessage: _sendPrompt,
          controller: _chatController,
        ),
      ),
    );
  }
}
