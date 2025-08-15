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

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    appleProvider: AppleProvider.debug,
    androidProvider: AndroidProvider.debug,
    webProvider: ReCaptchaV3Provider('debug'),
  );
  runApp(const FcpToolsExample());
}

class FcpToolsExample extends StatefulWidget {
  const FcpToolsExample({super.key});

  @override
  State<FcpToolsExample> createState() => _FcpToolsExampleState();
}

class _FcpToolsExampleState extends State<FcpToolsExample> {
  late final FcpSurfaceManager _surfaceManager;
  late final AiClient _aiClient;
  final List<ChatMessage> _chatHistory = [];
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _surfaceManager = FcpSurfaceManager();
    final manageUiTool = ManageUiTool(_surfaceManager);
    final widgetCatalog = WidgetCatalog(items: {}, dataTypes: {});
    final getWidgetCatalogTool = GetWidgetCatalogTool(widgetCatalog);
    _aiClient = GeminiAiClient(
      tools: [...manageUiTool.tools, getWidgetCatalogTool.get],
    );
  }

  @override
  void dispose() {
    _surfaceManager.dispose();
    super.dispose();
  }

  Future<void> _sendPrompt() async {
    final prompt = _textController.text;
    if (prompt.isEmpty) return;

    setState(() {
      _chatHistory.add(UserMessage.text(prompt));
    });
    _textController.clear();

    final response = await _aiClient.generateContent(
      _chatHistory,
      Schema.object(
        properties: {
          'response': Schema.string(description: 'The response to the user.'),
        },
      ),
    );

    setState(() {
      _chatHistory.add(
        AssistantMessage.text(
          (response as Map<String, Object?>)['response'] as String,
        ),
      );
    });
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
                      // TODO(gspencer): Provide a real catalog and registry.
                      catalog: WidgetCatalog(items: {}, dataTypes: {}),
                      registry: WidgetCatalogRegistry(),
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
