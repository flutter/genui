// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart' hide Action;
import 'package:gulf_client/gulf_client.dart';

void main() {
  runApp(const ExampleApp());
}

const String _sampleJsonl = r'''
{"streamHeader": {"version": "1.0.0"}}
{"componentUpdate": {"components": [{"id": "root", "componentProperties": {"Column": {"children": {"explicitList": ["profile_card"]}}}}]}}
{"componentUpdate": {"components": [{"id": "profile_card", "componentProperties": {"Card": {"child": "card_content"}}}]}}
{"componentUpdate": {"components": [{"id": "card_content", "componentProperties": {"Column": {"children": {"explicitList": ["header_row", "bio_text", "stats_row", "interaction_row"]}}}}]}}
{"componentUpdate": {"components": [{"id": "header_row", "componentProperties": {"Row": {"alignment": "center", "children": {"explicitList": ["avatar", "name_column"]}}}}]}}
{"componentUpdate": {"components": [{"id": "avatar", "componentProperties": {"Image": {"url": {"literalString": "https://www.gravatar.com/avatar/00000000000000000000000000000000?d=mp&f=y&s=128"}}}}]}}
{"componentUpdate": {"components": [{"id": "name_column", "componentProperties": {"Column": {"alignment": "start", "children": {"explicitList": ["name_text", "handle_text"]}}}}]}}
{"componentUpdate": {"components": [{"id": "name_text", "componentProperties": {"Heading": {"level": "3", "text": {"literalString": "Flutter Fan"}}}}]}}
{"componentUpdate": {"components": [{"id": "handle_text", "componentProperties": {"Text": {"text": {"literalString": "@flutterdev"}}}}]}}
{"componentUpdate": {"components": [{"id": "bio_text", "componentProperties": {"Text": {"text": {"literalString": "Building beautiful, natively compiled applications for mobile, web, and desktop from a single codebase."}}}}]}}
{"componentUpdate": {"components": [{"id": "stats_row", "componentProperties": {"Row": {"distribution": "spaceAround", "children": {"explicitList": ["followers_stat", "following_stat", "likes_stat"]}}}}]}}
{"componentUpdate": {"components": [{"id": "followers_stat", "componentProperties": {"Column": {"children": {"explicitList": ["followers_count", "followers_label"]}}}}]}}
{"componentUpdate": {"components": [{"id": "followers_count", "componentProperties": {"Text": {"text": {"literalString": "1.2M"}}}}]}}
{"componentUpdate": {"components": [{"id": "followers_label", "componentProperties": {"Text": {"text": {"literalString": "Followers"}}}}]}}
{"componentUpdate": {"components": [{"id": "following_stat", "componentProperties": {"Column": {"children": {"explicitList": ["following_count", "following_label"]}}}}]}}
{"componentUpdate": {"components": [{"id": "following_count", "componentProperties": {"Text": {"text": {"literalString": "280"}}}}]}}
{"componentUpdate": {"components": [{"id": "following_label", "componentProperties": {"Text": {"text": {"literalString": "Following"}}}}]}}
{"componentUpdate": {"components": [{"id": "likes_stat", "componentProperties": {"Column": {"children": {"explicitList": ["likes_count", "likes_label"]}}}}]}}
{"componentUpdate": {"components": [{"id": "likes_count", "componentProperties": {"Text": {"text": {"literalString": "10M"}}}}]}}
{"componentUpdate": {"components": [{"id": "likes_label", "componentProperties": {"Text": {"text": {"literalString": "Likes"}}}}]}}
{"componentUpdate": {"components": [{"id": "interaction_row", "componentProperties": {"Row": {"children": {"explicitList": ["follow_button", "message_field"]}}}}]}}
{"componentUpdate": {"components": [{"id": "follow_button", "componentProperties": {"Button": {"label": {"literalString": "Follow"}, "action": {"action": "follow_user"}}}}]}}
{"componentUpdate": {"components": [{"id": "message_field", "componentProperties": {"TextField": {"label": {"literalString": "Send a message..."}}}}]}}
{"dataModelUpdate": {"contents": {}}}
{"beginRendering": {"root": "root"}}
''';

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('GULF Client Example')),
        body: const ExampleView(),
      ),
    );
  }
}

class ExampleView extends StatefulWidget {
  const ExampleView({super.key});

  @override
  State<ExampleView> createState() => _ExampleViewState();
}

class _ExampleViewState extends State<ExampleView> {
  GulfInterpreter? interpreter;
  final registry = WidgetRegistry();
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    registry.register('ColumnProperties', (
      context,
      component,
      properties,
      children,
    ) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: _getMainAxisAlignment(
          properties['distribution'] as String?,
        ),
        crossAxisAlignment: _getCrossAxisAlignment(
          properties['alignment'] as String?,
        ),
        children: children['children'] ?? [],
      );
    });
    registry.register('RowProperties', (
      context,
      component,
      properties,
      children,
    ) {
      return Row(
        mainAxisAlignment: _getMainAxisAlignment(
          properties['distribution'] as String?,
        ),
        crossAxisAlignment: _getCrossAxisAlignment(
          properties['alignment'] as String?,
        ),
        children: children['children'] ?? [],
      );
    });
    registry.register('TextProperties', (
      context,
      component,
      properties,
      children,
    ) {
      final text = properties['text'] as String? ?? '';
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
        child: Text(text),
      );
    });
    registry.register('HeadingProperties', (
      context,
      component,
      properties,
      children,
    ) {
      final text = properties['text'] as String? ?? '';
      final level = (component.componentProperties as HeadingProperties).level;
      TextStyle? style;
      style = switch (level) {
        '1' => Theme.of(context).textTheme.headlineSmall,
        '2' => Theme.of(context).textTheme.titleLarge,
        '3' => Theme.of(context).textTheme.titleMedium,
        '4' => Theme.of(context).textTheme.bodyLarge,
        '5' => Theme.of(context).textTheme.bodyMedium,
        '6' => Theme.of(context).textTheme.bodySmall,
        _ => Theme.of(context).textTheme.bodyMedium,
      };
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
        child: Text(text, style: style),
      );
    });
    registry.register('ImageProperties', (
      context,
      component,
      properties,
      children,
    ) {
      final url = properties['url'] as String?;
      if (url == null) {
        return const Padding(
          padding: EdgeInsets.all(8.0),
          child: Icon(Icons.broken_image),
        );
      }
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.network(url, width: 64, height: 64),
      );
    });
    registry.register('CardProperties', (
      context,
      component,
      properties,
      children,
    ) {
      return Card(
        margin: const EdgeInsets.all(8.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: children['child']?.first,
        ),
      );
    });
    registry.register('ButtonProperties', (
      context,
      component,
      properties,
      children,
    ) {
      final action = properties['action'] as Action;
      return ElevatedButton(
        onPressed: () {
          GulfProvider.of(context)?.onEvent?.call({'action': action.action});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Event: ${action.action}'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        child: Text(properties['label'] as String? ?? ''),
      );
    });
    registry.register('TextFieldProperties', (
      context,
      component,
      properties,
      children,
    ) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: properties['label'] as String?,
            ),
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  MainAxisAlignment _getMainAxisAlignment(String? alignment) {
    switch (alignment) {
      case 'start':
        return MainAxisAlignment.start;
      case 'end':
        return MainAxisAlignment.end;
      case 'center':
        return MainAxisAlignment.center;
      case 'spaceBetween':
        return MainAxisAlignment.spaceBetween;
      case 'spaceAround':
        return MainAxisAlignment.spaceAround;
      case 'spaceEvenly':
        return MainAxisAlignment.spaceEvenly;
      default:
        return MainAxisAlignment.start;
    }
  }

  CrossAxisAlignment _getCrossAxisAlignment(String? alignment) {
    switch (alignment) {
      case 'start':
        return CrossAxisAlignment.start;
      case 'end':
        return CrossAxisAlignment.end;
      case 'center':
        return CrossAxisAlignment.center;
      case 'stretch':
        return CrossAxisAlignment.stretch;
      // Flutter no longer supports baseline alignment for all widgets.
      // case 'baseline':
      //   return CrossAxisAlignment.baseline;
      default:
        return CrossAxisAlignment.center;
    }
  }

  void _renderJsonl() {
    final jsonl = _textController.text;
    if (jsonl.trim().isEmpty) {
      setState(() {
        interpreter = null;
      });
      return;
    }

    final streamController = StreamController<String>();
    final newInterpreter = GulfInterpreter(stream: streamController.stream);

    setState(() {
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
                  _textController.text = _sampleJsonl;
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
                  : SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GulfView(
                          interpreter: interpreter!,
                          registry: registry,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
