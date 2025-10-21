// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:a2ui_client/a2ui_client.dart';
import 'package:flutter/material.dart' hide Action;

import 'sample_data.dart';
import 'widgets.dart';

class ManualInputView extends StatefulWidget {
  const ManualInputView({super.key});

  @override
  State<ManualInputView> createState() => _ManualInputViewState();
}

class _ManualInputViewState extends State<ManualInputView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  A2uiInterpreter? interpreter;
  final registry = WidgetRegistry();
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    registerA2uiWidgets(registry);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _renderJsonl() {
    final jsonl = _textController.text;
    if (jsonl.trim().isEmpty) {
      setState(() {
        interpreter?.dispose();
        interpreter = null;
      });
      return;
    }

    final streamController = StreamController<String>();
    final newInterpreter = A2uiInterpreter(stream: streamController.stream);

    setState(() {
      interpreter?.dispose();
      interpreter = newInterpreter;
    });

    final lines = jsonl.split('\n');
    for (final line in lines) {
      if (line.trim().isNotEmpty) {
        streamController.add(line);
      }
    }
    streamController.close();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _textController,
            maxLines: 8,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter JSONL here',
              labelText: 'JSONL Input',
            ),
            style: const TextStyle(fontFamily: 'monospace'),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  _textController.text = sampleJsonl;
                },
                child: const Text('Load Sample'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _renderJsonl,
                child: const Text('Render JSONL'),
              ),
            ],
          ),
          const Divider(height: 20, thickness: 2),
          Expanded(
            child: Card(
              elevation: 2,
              child: interpreter == null
                  ? const Center(
                      child: Text('Submit JSONL to see the rendered UI.'),
                    )
                  : A2uiView(interpreter: interpreter!, registry: registry),
            ),
          ),
        ],
      ),
    );
  }
}
