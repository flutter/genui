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

/// A travel planner screen with UI on the left and chat on the right.
///
/// This screen uses a [TravelPlannerCanvasController] to manage state and
/// shows UI surfaces on the left pane and text chat on the right pane.
class SideChatTravelPlanner extends StatefulWidget {
  /// Creates a new [SideChatTravelPlanner].
  ///
  /// An optional [controller] can be provided for testing. If not provided,
  /// a default controller will be created with chat output enabled.
  const SideChatTravelPlanner({this.controller, super.key});

  /// The controller to use for managing state.
  ///
  /// If null, a default controller with chat output enabled will be created.
  final TravelPlannerCanvasController? controller;

  @override
  State<SideChatTravelPlanner> createState() => _SideChatTravelPlannerState();
}

class _SideChatTravelPlannerState extends State<SideChatTravelPlanner> {
  late final TravelPlannerCanvasController _controller;
  late final StreamSubscription<Iterable<AiUiMessage>> _surfacesSubscription;
  late final StreamSubscription<Iterable<ChatMessage>>
  _textMessagesSubscription;
  late final StreamSubscription<bool> _isThinkingSubscription;

  final _textController = TextEditingController();
  final _uiScrollController = ScrollController();
  final _chatScrollController = ScrollController();

  List<AiUiMessage> _surfaces = [];
  List<ChatMessage> _textMessages = [];
  bool _isThinking = false;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ??
        TravelPlannerCanvasController(enableChatOutput: true);

    _surfacesSubscription = _controller.surfaces.listen((surfaces) {
      setState(() {
        _surfaces = surfaces.toList();
      });
      _scrollToBottom(_uiScrollController);
    });

    _textMessagesSubscription = _controller.textMessages.listen((messages) {
      setState(() {
        _textMessages = messages.toList();
      });
      _scrollToBottom(_chatScrollController);
    });

    _isThinkingSubscription = _controller.isThinking.listen((thinking) {
      setState(() {
        _isThinking = thinking;
      });
    });

    // Initialize with current state
    _surfaces = _controller.currentSurfaces.toList();
    _textMessages = _controller.currentTextMessages.toList();
    _isThinking = _controller.currentIsThinking;
  }

  @override
  void dispose() {
    _surfacesSubscription.cancel();
    _textMessagesSubscription.cancel();
    _isThinkingSubscription.cancel();
    _textController.dispose();
    _uiScrollController.dispose();
    _chatScrollController.dispose();

    // Only dispose controller if we created it
    if (widget.controller == null) {
      _controller.dispose();
    }

    super.dispose();
  }

  void _scrollToBottom(ScrollController controller) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.hasClients) {
        controller.animateTo(
          controller.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(String text) {
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
            SizedBox(width: 16.0),
            Text('Travel Inc. - Side Chat'),
          ],
        ),
        actions: [const Icon(Icons.person_outline), const SizedBox(width: 8.0)],
      ),
      drawer: const TravelAppDrawer(),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: Theme.of(context).dividerColor,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              border: Border(
                                bottom: BorderSide(
                                  color: Theme.of(context).dividerColor,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.dashboard,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Travel Planning Canvas',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _surfaces.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.travel_explore,
                                          size: 64,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.outline,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Start planning your trip',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall
                                              ?.copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.outline,
                                              ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.only(bottom: 40),
                                    child: Conversation(
                                      messages: _surfaces,
                                      manager: _controller.genUiManager,
                                      scrollController: _uiScrollController,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  ///
                  /// Separation
                  ///
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            border: Border(
                              bottom: BorderSide(
                                color: Theme.of(context).dividerColor,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.chat,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Chat',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _textMessages.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.chat_bubble_outline,
                                        size: 48,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.outline,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Start a conversation',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.outline,
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              : Padding(
                                  padding: const EdgeInsets.only(bottom: 60),
                                  child: Conversation(
                                    messages: _textMessages,
                                    manager: _controller.genUiManager,
                                    scrollController: _chatScrollController,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ChatInput(
                controller: _textController,
                isThinking: _isThinking,
                onSend: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
