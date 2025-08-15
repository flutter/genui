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
  late AiClient _aiClient;
  final List<ChatMessage> _chatHistory = [];
  final TextEditingController _textController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = FcpToolsProvider.of(context);
    _surfaceManager = provider.surfaceManager;
    _aiClient = provider.aiClient;
  }

  Future<void> _sendPrompt() async {
    final prompt = _textController.text;
    if (prompt.isEmpty) return;

    setState(() {
      _chatHistory.add(UserMessage.text(prompt));
    });
    _textController.clear();

    await _aiClient.generateContent(
      _chatHistory,
      Schema.object(properties: {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('FCP Tools Example')),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _chatHistory.length,
                itemBuilder: (context, index) {
                  final message = _chatHistory[index];
                  return ListTile(
                    title: Text(
                      message is UserMessage
                          ? (message.parts.first as TextPart).text
                          : (message as AssistantMessage).parts.isNotEmpty
                          ? (message.parts.first as TextPart).text
                          : '',
                    ),
                    leading: Icon(
                      message is UserMessage ? Icons.person : Icons.computer,
                    ),
                  );
                },
              ),
            ),
            AnimatedBuilder(
              animation: _surfaceManager,
              builder: (context, child) {
                return Column(
                  children: _surfaceManager.listSurfaces().map((surfaceId) {
                    final packet = _surfaceManager.getPacket(surfaceId);
                    if (packet == null) return const SizedBox.shrink();
                    return FcpView(
                      packet: packet,
                      catalog: exampleCatalog.buildCatalog(),
                      registry: exampleCatalog,
                      controller: _surfaceManager.getController(surfaceId),
                    );
                  }).toList(),
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
                        hintText: 'Enter a prompt...',
                      ),
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
