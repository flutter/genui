// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ai_client/ai_client.dart';
import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:fcp_client/fcp_client.dart';
import 'package:fcp_tools/fcp_tools.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'app_host.dart';
import 'catalog.dart';
import 'firebase_options.dart';

Future<void> main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint(
      '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}',
    );
  });
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    appleProvider: AppleProvider.debug,
    androidProvider: AndroidProvider.debug,
    webProvider: ReCaptchaV3Provider('debug'),
  );
  runApp(const AppHost(child: FcpToolsExample()));
}

class FcpToolsExample extends StatefulWidget {
  const FcpToolsExample({super.key});

  @override
  State<FcpToolsExample> createState() => _FcpToolsExampleState();
}

class _FcpToolsExampleState extends State<FcpToolsExample> {
  late FcpSurfaceManager _surfaceManager;
  late ConversationHistoryManager _conversationHistoryManager;
  late AiClient _aiClient;
  final TextEditingController _textController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = FcpToolsProvider.of(context);
    _surfaceManager = provider.surfaceManager;
    _conversationHistoryManager = provider.conversationHistoryManager;
    _aiClient = provider.aiClient;
  }

  Future<void> _sendPrompt() async {
    final prompt = _textController.text;
    if (prompt.isEmpty) return;
    _textController.clear();

    _conversationHistoryManager.addMessage(UserMessage([TextPart(prompt)]));
    final messages = _conversationHistoryManager.messages;

    // // Create a copy of the history for the AI client to modify.
    final originalMessageCount = messages.length;
    final response = await _aiClient.generateContent<String>(
      _conversationHistoryManager.messages,
      Schema.string(),
    );
    if (response != null) {
      _conversationHistoryManager.addMessage(
        AssistantMessage([TextPart(response)]),
      );
    }

    if (messages.length > originalMessageCount) {
      final newMessages = messages.sublist(originalMessageCount);
      for (final message in newMessages) {
        _conversationHistoryManager.addMessage(message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('FCP Tools Example')),
        body: Column(
          children: [
            Expanded(
              child: ListenableBuilder(
                listenable: _conversationHistoryManager,
                builder: (context, child) {
                  final history = _conversationHistoryManager.history;
                  return ListView.builder(
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final entry = history[index];
                      return switch (entry) {
                        MessageEntry(:final message) => ListTile(
                          leading: Icon(
                            message is UserMessage
                                ? Icons.person
                                : Icons.computer,
                          ),
                          title: Text(_extractText(message)),
                        ),
                        SurfaceEntry(:final surfaceId) => Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: FcpView(
                            packet: _surfaceManager.getPacket(surfaceId)!,
                            catalog: exampleCatalog.buildCatalog(),
                            registry: exampleCatalog,
                            controller: _surfaceManager.getController(
                              surfaceId,
                            ),
                          ),
                        ),
                      };
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: 'Enter a prompt...',
                      ),
                      onSubmitted: (_) => _sendPrompt(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendPrompt,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _extractText(ChatMessage message) {
  return switch (message) {
    UserMessage(:final parts) =>
      parts.whereType<TextPart>().map((p) => p.text).join(),
    AssistantMessage(:final parts) =>
      parts.whereType<TextPart>().map((p) => p.text).join(),
    _ => '',
  };
}
