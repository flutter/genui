// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

import '../controllers/travel_planner_canvas_controller.dart';
import '../widgets/conversation.dart';
import '../widgets/drawer.dart';

/// A travel planner screen with UI only, no visible chat.
///
/// This screen uses a [TravelPlannerCanvasController] to manage state and
/// shows only UI surfaces. If no surfaces are present, it shows an empty
/// state with a centered prompt to get started.
class NoChatTravelPlanner extends StatefulWidget {
  /// Creates a new [NoChatTravelPlanner].
  ///
  /// An optional [aiClient] can be provided for testing. If not provided,
  /// a default controller will be created with chat output disabled.
  const NoChatTravelPlanner({this.aiClient, super.key});

  /// The AI client to use for the application.
  ///
  /// If null, a default controller with chat output disabled will be created.
  final AiClient? aiClient;

  @override
  State<NoChatTravelPlanner> createState() => _NoChatTravelPlannerState();
}

class _NoChatTravelPlannerState extends State<NoChatTravelPlanner> {
  late final TravelPlannerCanvasController _controller;
  late final StreamSubscription<Iterable<AiUiMessage>> _surfacesSubscription;
  late final StreamSubscription<bool> _isThinkingSubscription;

  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  List<AiUiMessage> _surfaces = [];
  bool _isThinking = false;

  @override
  void initState() {
    super.initState();
    _controller = TravelPlannerCanvasController(
      enableChatOutput: false,
      aiClient: widget.aiClient,
    );

    _surfacesSubscription = _controller.surfaces.listen((surfaces) {
      setState(() {
        _surfaces = surfaces.toList();
      });
      _scrollToBottom();
    });

    _isThinkingSubscription = _controller.isThinking.listen((thinking) {
      setState(() {
        _isThinking = thinking;
      });
    });

    // Initialize with current state
    _surfaces = _controller.currentSurfaces.toList();
    _isThinking = _controller.currentIsThinking;
  }

  @override
  void dispose() {
    _surfacesSubscription.cancel();
    _isThinkingSubscription.cancel();
    _textController.dispose();
    _scrollController.dispose();

    // Always dispose controller since we always create it
    _controller.dispose();

    super.dispose();
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

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    _controller.sendUserTextMessage(text);
    _textController.clear();
  }

  Widget _buildLoadingIndicator() {
    if (!_isThinking) return const SizedBox.shrink();

    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Planning...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Travel icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.flight_takeoff,
                size: 48,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 32),

            Text(
              'Where do you want to go?',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            Text(
              'Tell me about your dream trip and I\'ll help you plan it',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            Text(
              'Try something from the list:',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip('Plan a weekend in Paris'),
                _buildSuggestionChip('Family trip to Japan'),
                _buildSuggestionChip('Backpacking through Europe'),
                _buildSuggestionChip('Romantic getaway ideas'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: _isThinking ? null : () => _sendMessage(text),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.local_airport),
            SizedBox(width: 16.0),
            Flexible(child: Text('Travel Inc. - Canvas')),
          ],
        ),
        actions: [const Icon(Icons.person_outline), const SizedBox(width: 8.0)],
      ),
      drawer: const TravelAppDrawer(),
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_surfaces.isEmpty)
              _buildEmptyState()
            else
              Conversation(
                messages: _surfaces,
                manager: _controller.genUiManager,
                scrollController: _scrollController,
              ),
            _buildLoadingIndicator(),
          ],
        ),
      ),
    );
  }
}
