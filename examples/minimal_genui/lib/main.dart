// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

import 'firebase_options.dart';

const _chatPrompt = '''
You are a helpful assistant who figures out what the user wants to do and then helps suggest options so they can develop a plan and find relevant information.

The user will ask questions, and you will respond by generating appropriate UI elements. Typically, you will first elicit more information to understand the user's needs, then you will start displaying information and the user's plans.

Typically, you should not update existing surfaces and instead just continually "add" new ones.

If the user says "hello" or another greeting, always respond with the hello_world widget.
''';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

const title = 'Minimal GenUI Example';

final helloWorldCatalogItem = CatalogItem(
  name: 'hello_world',
  dataSchema: S.object(
    description: 'A widget to greet the user',
    properties: {
      'message': S.string(description: 'The message to display to the user.'),
    },
    required: ['message'],
  ),
  widgetBuilder:
      ({
        required data,
        required id,
        required buildChild,
        required dispatchEvent,
        required context,
      }) {
        var message = (data as Map<String, Object?>)['message'] as String;
        return Column(
          children: [
            Text(
              'Hello world',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(message),
          ],
        );
      },
);

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
  final GenUiManager _genUiManager = GenUiManager.chat(
    aiClient: GeminiAiClient(systemInstruction: _chatPrompt),
    catalog: Catalog([...coreWidgets, helloWorldCatalogItem]),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _genUiManager.widget(),
      ),
    );
  }
}
