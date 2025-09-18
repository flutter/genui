// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gulf_client/gulf_client.dart';

void main() {
  runApp(const ExampleApp());
}

const String _sampleJsonl = r'''
{"messageType": "StreamHeader", "version": "1.0.0"}
{"messageType": "ComponentUpdate", "components": [{"id": "root", "type": "Column", "children": {"explicitList": ["profile_card"]}}]}
{"messageType": "ComponentUpdate", "components": [{"id": "profile_card", "type": "Card", "child": "card_content"}]}
{"messageType": "ComponentUpdate", "components": [{"id": "card_content", "type": "Column", "children": {"explicitList": ["header_row", "bio_text", "stats_row", "interaction_row"]}}]}
{"messageType": "ComponentUpdate", "components": [{"id": "header_row", "type": "Row", "alignment": "center", "children": {"explicitList": ["avatar", "name_column"]}}]}
{"messageType": "ComponentUpdate", "components": [{"id": "avatar", "type": "Image", "value": {"literalString": "https://www.gravatar.com/avatar/00000000000000000000000000000000?d=mp&f=y&s=128"}}]}
{"messageType": "ComponentUpdate", "components": [{"id": "name_column", "type": "Column", "alignment": "start", "children": {"explicitList": ["name_text", "handle_text"]}}]}
{"messageType": "ComponentUpdate", "components": [{"id": "name_text", "type": "Text", "level": 3, "value": {"literalString": "Flutter Fan"}}]}
{"messageType": "ComponentUpdate", "components": [{"id": "handle_text", "type": "Text", "level": 5, "value": {"literalString": "@flutterdev"}}]}
{"messageType": "ComponentUpdate", "components": [{"id": "bio_text", "type": "Text", "level": 4, "value": {"literalString": "Building beautiful, natively compiled applications for mobile, web, and desktop from a single codebase."}}]}
{"messageType": "ComponentUpdate", "components": [{"id": "stats_row", "type": "Row", "distribution": "spaceAround", "children": {"explicitList": ["followers_stat", "following_stat", "likes_stat"]}}]}
{"messageType": "ComponentUpdate", "components": [{"id": "followers_stat", "type": "Column", "children": {"explicitList": ["followers_count", "followers_label"]}}]}
{"messageType": "ComponentUpdate", "components": [{"id": "followers_count", "type": "Text", "level": 4, "value": {"literalString": "1.2M"}}]}
{"messageType": "ComponentUpdate", "components": [{"id": "followers_label", "type": "Text", "level": 6, "value": {"literalString": "Followers"}}]}
{"messageType": "ComponentUpdate", "components": [{"id": "following_stat", "type": "Column", "children": {"explicitList": ["following_count", "following_label"]}}]}
{"messageType": "ComponentUpdate", "components": [{"id": "following_count", "type": "Text", "level": 4, "value": {"literalString": "280"}}]}
{"messageType": "ComponentUpdate", "components": [{"id": "following_label", "type": "Text", "level": 6, "value": {"literalString": "Following"}}]}
{"messageType": "ComponentUpdate", "components": [{"id": "likes_stat", "type": "Column", "children": {"explicitList": ["likes_count", "likes_label"]}}]}
{"messageType": "ComponentUpdate", "components": [{"id": "likes_count", "type": "Text", "level": 4, "value": {"literalString": "10M"}}]}
{"messageType": "ComponentUpdate", "components": [{"id": "likes_label", "type": "Text", "level": 6, "value": {"literalString": "Likes"}}]}
{"messageType": "ComponentUpdate", "components": [{"id": "interaction_row", "type": "Row", "children": {"explicitList": ["follow_button", "message_field"]}}]}
{"messageType": "ComponentUpdate", "components": [{"id": "follow_button", "type": "Button", "label": "Follow", "action": {"action": "follow_user"}}]}
{"messageType": "ComponentUpdate", "components": [{"id": "message_field", "type": "TextField", "description": "Send a message..."}]}
{"messageType": "DataModelUpdate", "nodes": [{"id": "data_root"}]}
{"messageType": "UIRoot", "root": "root", "dataModelRoot": "data_root"}
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
    registry.register('Column', (context, component, properties, children) {
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
    registry.register('Row', (context, component, properties, children) {
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
    registry.register('Text', (context, component, properties, children) {
      final text = component.value?.literalString ?? '';
      final level = component.level;
      TextStyle? style;
      if (level != null) {
        style = switch (level) {
          1 => Theme.of(context).textTheme.headlineSmall,
          2 => Theme.of(context).textTheme.titleLarge,
          3 => Theme.of(context).textTheme.titleMedium,
          4 => Theme.of(context).textTheme.bodyLarge,
          5 => Theme.of(context).textTheme.bodyMedium,
          6 => Theme.of(context).textTheme.bodySmall,
          _ => Theme.of(context).textTheme.bodyMedium,
        };
      }
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
        child: Text(text, style: style),
      );
    });
    registry.register('Image', (context, component, properties, children) {
      final url = component.value?.literalString;
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
    registry.register('Card', (context, component, properties, children) {
      return Card(
        margin: const EdgeInsets.all(8.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: children['child']?.first,
        ),
      );
    });
    registry.register('Button', (context, component, properties, children) {
      return ElevatedButton(
        onPressed: () {
          GulfProvider.of(
            context,
          )?.onEvent?.call({'action': component.action?.action});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Event: ${component.action?.action}'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        child: Text(component.label ?? ''),
      );
    });
    registry.register('TextField', (context, component, properties, children) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: TextField(
            decoration: InputDecoration(hintText: component.description),
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
