// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart' hide Action;
import 'package:gulf_client/gulf_client.dart';

import 'widgets.dart';

class AgentConnectionView extends StatefulWidget {
  const AgentConnectionView({super.key});

  @override
  State<AgentConnectionView> createState() => _AgentConnectionViewState();
}

class _AgentConnectionViewState extends State<AgentConnectionView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  GulfInterpreter? interpreter;
  GulfAgentConnector? _connector;
  AgentCard? _agentCard;
  final registry = WidgetRegistry();
  final _urlController = TextEditingController(text: 'http://localhost:10002');
  final _messageController = TextEditingController(
    text:
        'Provide me a list of great italian restaurants in New York in lower '
        'manhattan',
  );

  @override
  void initState() {
    super.initState();
    registerGulfWidgets(registry);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _messageController.dispose();
    _connector?.dispose();
    interpreter?.dispose();
    super.dispose();
  }

  Future<void> _fetchCard() async {
    final url = Uri.tryParse(_urlController.text);
    if (url == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid URL')));
      return;
    }

    // Clean up previous connections
    _connector?.dispose();
    interpreter?.dispose();

    final newConnector = GulfAgentConnector(url: url);
    try {
      final card = await newConnector.getAgentCard();
      if (!mounted) return;
      setState(() {
        _connector = newConnector;
        _agentCard = card;
        // Create the interpreter once we have a valid connector
        interpreter?.dispose();
        interpreter = GulfInterpreter(stream: newConnector.stream);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching agent card: $e')));
    }
  }

  void _sendMessage() {
    if (_connector == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fetch agent card first')),
      );
      return;
    }
    _connector!.connectAndSend(_messageController.text);
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
            controller: _urlController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter agent URL',
              labelText: 'Agent URL',
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _fetchCard,
            child: const Text('Fetch Agent Card'),
          ),
          if (_agentCard != null)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Name: ${_agentCard!.name}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text('Description: ${_agentCard!.description}'),
                    Text('Version: ${_agentCard!.version}'),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _messageController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter message to agent',
              labelText: 'Message',
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _sendMessage,
            child: const Text('Send Message'),
          ),
          const Divider(height: 20, thickness: 2),
          Expanded(
            child: Card(
              elevation: 2,
              child: interpreter == null
                  ? const Center(child: Text('Send a message to see the UI.'))
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
