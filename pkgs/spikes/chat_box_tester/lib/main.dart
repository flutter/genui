// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

void main() {
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
      home: const _MyHomePage(),
    );
  }
}

class _MyHomePage extends StatefulWidget {
  const _MyHomePage();

  @override
  State<_MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<_MyHomePage> {
  late ChatBoxController _chatController = ChatBoxController(onInputSubmitted);
  final _log = TextEditingController(text: '');

  void onInputSubmitted(String input) {
    _addLogEntry('User: $input');
    _emulateStartProcessing();
  }

  void _addLogEntry(String entry) {
    _log.text = '$entry\n${_log.text}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Chat Box Tester'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(child: ChatBox(_chatController)),
          const SizedBox(height: 10),
          Container(
            color: Colors.grey[200],
            child: SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _log,
                      readOnly: true,
                      decoration: null,
                      maxLines: null,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _emulateStartProcessing,
                        child: const Text('Emulate AI request from other UI'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _addLogEntry('AI: responded');
                          _chatController.setResponded();
                        },
                        child: const Text('Emulate AI response'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _chatController = ChatBoxController(onInputSubmitted);
                          _log.text = '';
                          setState(() {});
                        },
                        child: const Text('Start over'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _emulateStartProcessing() {
    _addLogEntry('AI: started processing');
    _chatController.setRequested();
  }
}
