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
  final Map<ChatMessage, String> _surfaceMap = {};
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

    final originalHistoryLength = _chatHistory.length;
    await _aiClient.generateContent(
      _chatHistory,
      Schema.object(properties: {}),
    );

    if (_chatHistory.length > originalHistoryLength) {
      final newMessages = _chatHistory.sublist(originalHistoryLength);
      for (final message in newMessages) {
        if (message is AssistantMessage) {
          String? surfaceId;
          for (final part in message.parts) {
            if (part is ToolCallPart && part.toolName == 'set') {
              final params =
                  part.arguments['parameters'] as Map<String, dynamic>?;
              surfaceId = params?['surfaceId'] as String?;
              if (surfaceId != null) {
                _surfaceMap[message] = surfaceId;
                break;
              }
            }
          }
        }
      }
    }
    setState(() {});
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
                listenable: _surfaceManager,
                builder: (context, child) {
                  final children = <Widget>[];
                  final renderedSurfaces = <String>{};
                  for (final message in _chatHistory) {
                    final surfaceId = _surfaceMap[message];
                    final textContent = switch (message) {
                      UserMessage() => message.parts
                          .whereType<TextPart>()
                          .map((p) => p.text)
                          .join(),
                      AssistantMessage() => message.parts
                          .whereType<TextPart>()
                          .map((p) => p.text)
                          .join(),
                      _ => '',
                    };

                    Widget titleWidget;
                    if (textContent.isNotEmpty) {
                      titleWidget = Text(textContent);
                    } else if (surfaceId == null &&
                        message is AssistantMessage) {
                      // Show something for non-text, non-surface assistant
                      // messages (e.g. tool call in progress).
                      titleWidget = const Text('...');
                    } else {
                      titleWidget = const SizedBox.shrink();
                    }

                    Widget? fcpView;
                    if (surfaceId != null) {
                      final packet = _surfaceManager.getPacket(surfaceId);
                      if (packet != null) {
                        fcpView = FcpView(
                          packet: packet,
                          catalog: exampleCatalog.buildCatalog(),
                          registry: exampleCatalog,
                          controller: _surfaceManager.getController(surfaceId),
                        );
                        renderedSurfaces.add(surfaceId);
                      }
                    }
                    children.add(
                      ListTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            titleWidget,
                            if (fcpView != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: fcpView,
                              ),
                          ],
                        ),
                        leading: Icon(
                          message is UserMessage
                              ? Icons.person
                              : Icons.computer,
                        ),
                      ),
                    );
                  }

                  for (final surfaceId in _surfaceManager.listSurfaces()) {
                    if (renderedSurfaces.contains(surfaceId)) {
                      continue;
                    }
                    final packet = _surfaceManager.getPacket(surfaceId);
                    if (packet != null) {
                      children.add(
                        FcpView(
                          packet: packet,
                          catalog: exampleCatalog.buildCatalog(),
                          registry: exampleCatalog,
                          controller: _surfaceManager.getController(surfaceId),
                        ),
                      );
                    }
                  }

                  return ListView(
                    children: children,
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
