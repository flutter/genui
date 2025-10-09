// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_genui_firebase_ai/flutter_genui_firebase_ai.dart';
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
  late final UiAgent uiAgent;
  final _textController = TextEditingController();

  final List<String> _surfaceIds = [];

  void _onSurfaceAdded(SurfaceAdded update) {
    setState(() {
      _surfaceIds.add(update.surfaceId);
    });
  }

  void _onSurfaceDeleted(SurfaceRemoved update) {
    setState(() {
      _surfaceIds.remove(update.surfaceId);
    });
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    uiAgent.sendRequest(UserMessage.text(text));
  }

  @override
  void initState() {
    super.initState();
    final genUiManager = GenUiManager(
      catalog: CoreCatalogItems.asCatalog().copyWith([riddleCard]),
    );
    final aiClient = FirebaseAiClient(
      systemInstruction: '''
          You are an expert in creating funny riddles. Every time I give you a
          word, you should generate a RiddleCard that displays one new riddle
          related to that word. Each riddle should have both a question and an
          answer.
          ''',
      tools: genUiManager.getTools(),
    );
    uiAgent = UiAgent(
      genUiManager: genUiManager,
      aiClient: aiClient,
      onTextResponse: (t) {
        debugPrint('TEXT: $t)');
      },
      onSurfaceAdded: _onSurfaceAdded,
      onSurfaceDeleted: _onSurfaceDeleted,
      onWarning: (value) => debugPrint('Warning from UiAgent: $value'),
    );
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
              itemCount: _surfaceIds.length,
              itemBuilder: (context, index) {
                final id = _surfaceIds[index];
                return GenUiSurface(host: uiAgent.host, surfaceId: id);
              },
            ),
          ),
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
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      _sendMessage(_textController.text);
                      _textController.clear();
                    },
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
  widgetBuilder:
      ({
        required data,
        required id,
        required buildChild,
        required dispatchEvent,
        required context,
        required dataContext,
      }) {
        final json = data as Map<String, Object?>;

        // 1. Resolve the question reference
        final questionRef = json['question'] as Map<String, Object?>;
        final questionPath = questionRef['path'] as String?;
        final questionLiteral = questionRef['literalString'] as String?;
        final questionNotifier = questionPath != null
            ? dataContext.subscribe<String>(questionPath)
            : ValueNotifier<String?>(questionLiteral);

        // 2. Resolve the answer reference
        final answerRef = json['answer'] as Map<String, Object?>;
        final answerPath = answerRef['path'] as String?;
        final answerLiteral = answerRef['literalString'] as String?;
        final answerNotifier = answerPath != null
            ? dataContext.subscribe<String>(answerPath)
            : ValueNotifier<String?>(answerLiteral);

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
