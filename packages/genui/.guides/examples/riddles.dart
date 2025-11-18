// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:genui_firebase_ai/genui_firebase_ai.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:logging/logging.dart';

import 'firebase_options.dart';

final logger = configureGenUiLogging(level: Level.ALL);
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  logger.onRecord.listen((record) {
    debugPrint('${record.loggerName}: ${record.message}');
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final GenUiConversation conversation;
  final _textController = TextEditingController();
  final List<ChatMessage> messages = [];

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    conversation.sendRequest(UserMessage.text(text));
    _textController.clear();
  }

  @override
  void initState() {
    super.initState();
    final genUiManager = GenUiManager(
      catalog: CoreCatalogItems.asCatalog().copyWith([riddleCard]),
    );
    final contentGenerator = FirebaseAiContentGenerator(
      systemInstruction: '''
          You are an expert in creating funny riddles. Every time I give you a
          word, you should generate a RiddleCard that displays one new riddle
          related to that word. Each riddle should have both a question and an
          answer.
          ''',
    );
    conversation = GenUiConversation(
      contentGenerator: contentGenerator,
      genUiManager: genUiManager,
      onSurfaceAdded: (update) {
        setState(() {
          messages.add(
            AiUiMessage(
              definition: update.definition,
              surfaceId: update.surfaceId,
            ),
          );
        });
      },
      onTextResponse: (text) {
        setState(() {
          messages.add(AiTextMessage.text(text));
        });
      },
      onError: (error) {
        setState(() {
          messages.add(
            InternalMessage('Error: ${error.error}'),
          );
        });
      },
    );
    conversation.conversation.addListener(() {
      // This is just to trigger a rebuild when the conversation history inside
      // GenUiConversation changes.
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return switch (message) {
                  AiUiMessage() => GenUiSurface(
                      key: message.uiKey,
                      host: conversation.host,
                      surfaceId: message.surfaceId,
                    ),
                  AiTextMessage() => ChatMessageWidget(
                      text: message.text,
                    isUser: false,
                    ),
                  UserMessage() => ChatMessageWidget(
                      text: message.text,
                    isUser: true,
                    ),
                  InternalMessage() =>
                    InternalMessageWidget(content: message.text),
                  _ => Text(message.toString()),
                };
              },
            ),
          ),
          if (conversation.isProcessing.value)
            const LinearProgressIndicator(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: 'Enter a message',
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => _sendMessage(_textController.text),
                    child: const Text('Send'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessageWidget extends StatelessWidget {
  const ChatMessageWidget({
    super.key,
    required this.text,
    required this.isUser,
  });

  final String text;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isUser
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        Icon(isUser ? Icons.person : Icons.computer),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isUser ? Colors.blue[100] : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(text),
          ),
        ),
      ],
    );
  }
}

class InternalMessageWidget extends StatelessWidget {
  const InternalMessageWidget({super.key, required this.content});
  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.yellow[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(child: Text(content)),
        ],
      ),
    );
  }
}

final _schema = S.object(
  properties: {
    'question': A2uiSchemas.stringReference(
      description: 'The question part of a riddle.',
    ),
    'answer': A2uiSchemas.stringReference(
      description: 'The answer part of a riddle.',
    ),
  },
  required: ['question', 'answer'],
);

final riddleCard = CatalogItem(
  name: 'RiddleCard',
  dataSchema: _schema,
  widgetBuilder: ({
    required data,
    required id,
    required buildChild,
    required dispatchEvent,
    required context,
    required dataContext,
  }) {
    final questionNotifier =
        dataContext.subscribeToString(json['question'] as Map<String, Object?>?);
    final answerNotifier =
        dataContext.subscribeToString(json['answer'] as Map<String, Object?>?);

    // 3. Use ValueListenableBuilder to build the UI reactively
    return ValueListenableBuilder<String?>(
      valueListenable: questionNotifier,
      builder: (context, question, _) {
        return ValueListenableBuilder<String?>(
          valueListenable: answerNotifier,
          builder: (context, answer, _) {
            return Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(border: Border.all()),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question ?? '',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    answer ?? '',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  },
);
