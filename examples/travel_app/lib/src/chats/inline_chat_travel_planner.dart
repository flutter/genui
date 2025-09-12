// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

import '../controllers/travel_planner_canvas_controller.dart';
import '../widgets/chat_input.dart';
import '../widgets/conversation.dart';
import '../widgets/drawer.dart';

/// The inline chat travel planner page.
///
/// This page displays both UI surfaces and text messages in a single
/// conversation view, similar to a traditional chat interface.
/// It uses a [TravelPlannerCanvasController] to manage state and
/// AI interactions.
class InlineChatTravelPlanner extends StatefulWidget {
  /// Creates a new [InlineChatTravelPlanner].
  ///
  /// An optional [aiClient] can be provided for testing. If not provided,
  /// a default controller will be created with chat output enabled.
  const InlineChatTravelPlanner({this.aiClient, this.controller, super.key});

  /// Optional parameter that could be used for writing test, as of now we're
  /// initalizing the controller in the [_InlineChatTravelPlannerState] itself
  final TravelPlannerCanvasController? controller;

  /// The AI client to use for the application.
  ///
  /// If null, a default controller with chat output enabled will be created.
  final AiClient? aiClient;

  @override
  State<InlineChatTravelPlanner> createState() =>
      _InlineChatTravelPlannerState();
}

class _InlineChatTravelPlannerState extends State<InlineChatTravelPlanner> {
  late final TravelPlannerCanvasController _controller;
  late final StreamSubscription<Iterable<AiUiMessage>> _surfacesSubscription;
  late final StreamSubscription<Iterable<ChatMessage>>
  _textMessagesSubscription;
  late final StreamSubscription<bool> _isThinkingSubscription;

  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  List<ChatMessage> _conversation = [];
  bool _isThinking = false;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ??
        TravelPlannerCanvasController(
          enableChatOutput: true,
          aiClient: widget.aiClient,
        );

    // Listen to controller streams and merge surfaces and text messages
    _surfacesSubscription = _controller.surfaces.listen((surfaces) {
      setState(_rebuildAllMessages);
      _scrollToBottom();
    });

    _textMessagesSubscription = _controller.textMessages.listen((messages) {
      setState(_rebuildAllMessages);
      _scrollToBottom();
    });

    _isThinkingSubscription = _controller.isThinking.listen((thinking) {
      setState(() {
        _isThinking = thinking;
      });
    });

    // Initialize with current state
    _rebuildAllMessages();
    _isThinking = _controller.currentIsThinking;
  }

  @override
  void dispose() {
    _surfacesSubscription.cancel();
    _textMessagesSubscription.cancel();
    _isThinkingSubscription.cancel();
    _textController.dispose();
    _scrollController.dispose();

    // Always dispose controller since we always create it
    _controller.dispose();

    super.dispose();
  }

  /// Rebuilds the combined message list from surfaces and text messages
  void _rebuildAllMessages() {
    _conversation = _controller.conversation.toList();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendPrompt(String text) {
    if (text.trim().isEmpty) return;
    _controller.sendUserTextMessage(text);
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.local_airport),
            SizedBox(width: 16.0), // Add spacing between icon and text
            Flexible(child: Text('Travel Inc. - Inline Chat')),
          ],
        ),
        actions: [const Icon(Icons.person_outline), const SizedBox(width: 8.0)],
      ),
      drawer: const TravelAppDrawer(),
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Conversation(
                    messages: _conversation,
                    manager: _controller.genUiManager,
                    scrollController: _scrollController,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ChatInput(
                  controller: _textController,
                  isThinking: _isThinking,
                  onSend: _sendPrompt,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
