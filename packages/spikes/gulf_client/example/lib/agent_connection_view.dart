// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart' hide Action;
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:gulf_client/gulf_client.dart';
import 'package:provider/provider.dart';

import 'agent_state.dart';
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

  bool _messageSent = false;
  final registry = WidgetRegistry();
  final _messageController = TextEditingController(
    text:
        'Provide me a list of great italian restaurants in New York in lower '
        'manhattan',
  );
  final List<ChatMessage> _chatHistory = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    registerGulfWidgets(registry);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _sendMessage(AgentState agentState) {
    if (agentState.connector == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fetch agent card first')),
      );
      return;
    }
    final message = _messageController.text;
    setState(() {
      _chatHistory.add(ChatMessage(text: message, isUser: true));
      _messageSent = true;
    });
    _scrollToBottom();
    agentState.connector!.connectAndSend(
      message,
      onResponse: (response) {
        setState(() {
          _chatHistory.add(ChatMessage(text: response, isUser: false));
        });
        _scrollToBottom();
      },
    );
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final agentState = context.watch<AgentState>();
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (agentState.agentCard != null)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Name: ${agentState.agentCard!.name}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text('Description: ${agentState.agentCard!.description}'),
                    Text('Version: ${agentState.agentCard!.version}'),
                  ],
                ),
              ),
            ),
          Expanded(
            child: Card(
              elevation: 2,
              child: agentState.interpreter == null || !_messageSent
                  ? const Center(child: Text('Send a message to see the UI.'))
                  : GulfView(
                      interpreter: agentState.interpreter!,
                      registry: registry,
                      onEvent: (event) {
                        agentState.connector?.sendEvent(event);
                      },
                      onDataModelUpdate: (path, value) {
                        agentState.interpreter!.updateData(path, value);
                      },
                    ),
            ),
          ),
          const Divider(height: 20, thickness: 2),
          Expanded(
            child: _ChatHistory(
              chatHistory: _chatHistory,
              scrollController: _scrollController,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter message to agent',
                    labelText: 'Message',
                  ),
                  onSubmitted: (_) => _sendMessage(agentState),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _sendMessage(agentState),
                child: const Text('Send'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChatHistory extends StatelessWidget {
  const _ChatHistory({
    required this.chatHistory,
    required this.scrollController,
  });

  final List<ChatMessage> chatHistory;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      itemCount: chatHistory.length,
      itemBuilder: (context, index) {
        final message = chatHistory[index];
        return Padding(
          padding: EdgeInsetsDirectional.only(
            start: message.isUser ? 16.0 : 0,
            end: message.isUser ? 0 : 16.0,
          ),
          child: Card(
            color: message.isUser
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsetsDirectional.all(8.0),
              child: Row(
                mainAxisAlignment: message.isUser
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                children: [
                  if (!message.isUser)
                    const Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: Icon(Icons.smart_toy),
                    ),
                  Flexible(
                    child: SelectionArea(child: GptMarkdown(message.text)),
                  ),
                  if (message.isUser)
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Icon(Icons.person),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
