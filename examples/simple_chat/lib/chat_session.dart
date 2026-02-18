// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';
import 'package:logging/logging.dart';

import 'ai_client.dart';
import 'ai_client_transport.dart';
import 'message.dart';

/// A class that manages the chat session state and logic.
class ChatSession extends ChangeNotifier {
  ChatSession({required AiClient aiClient}) {
    // 1. Create Transport
    _transport = AiClientTransport(aiClient: aiClient);

    // 2. Initialize Catalog & Controller
    final Catalog catalog = BasicCatalogItems.asCatalog();
    _surfaceController = SurfaceController(catalogs: [catalog]);

    // 3. Initialize Conversation
    _conversation = Conversation(
      controller: _surfaceController,
      transport: _transport,
    );
    _init(catalog);
  }

  late final AiClientTransport _transport;
  late final SurfaceController _surfaceController;
  late final Conversation _conversation;

  SurfaceHost get surfaceController => _surfaceController;

  bool get isProcessing => _conversation.state.value.isWaiting;

  final List<Message> _messages = [];
  List<Message> get messages => List.unmodifiable(_messages);

  final Logger _logger = Logger('ChatSession');

  void _init(Catalog catalog) {
    // Listener for Conversation state
    _conversation.state.addListener(notifyListeners);

    // Listener for Conversation events
    _conversation.events.listen((event) {
      switch (event) {
        case ConversationSurfaceAdded(:final surfaceId):
          _addSurfaceMessage(surfaceId);
        case ConversationContentReceived(:final text):
          _updateAiMessage(text);
        case ConversationError(:final error):
          _logger.severe('Error in conversation', error);
          _messages.add(Message(isUser: false, text: 'Error: $error'));
          notifyListeners();
        case ConversationWaiting():
        case ConversationComponentsUpdated():
        case ConversationSurfaceRemoved():
          // No-op for now
          break;
      }
    });

    final promptBuilder = PromptBuilder.chat(
      catalog: catalog,
      instructions:
          'You are a helpful assistant who chats with a user. '
          'Your responses should contain acknowledgment of the user message.',
    );
    _transport.addSystemMessage(promptBuilder.systemPrompt);
  }

  void _addSurfaceMessage(String surfaceId) {
    final bool exists = _messages.any((m) => m.surfaceId == surfaceId);
    if (!exists) {
      _messages.add(Message(isUser: false, text: null, surfaceId: surfaceId));
      notifyListeners();
    }
  }

  Message? _currentAiMessage;

  void _updateAiMessage(String chunk) {
    if (_currentAiMessage == null) {
      _currentAiMessage = Message(isUser: false, text: '');
      _messages.add(_currentAiMessage!);
    }
    _currentAiMessage!.text = (_currentAiMessage!.text ?? '') + chunk;
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (text.isEmpty) return;

    // Reset current AI message so new response gets a new bubble
    _currentAiMessage = null;

    _messages.add(Message(isUser: true, text: 'You: $text'));
    // Do NOT notify here if we want to wait for "isWaiting" to update?
    // Actually we want to show user message immediately.
    notifyListeners();

    final message = ChatMessage.user(text);
    await _conversation.sendRequest(message);
  }

  @override
  void dispose() {
    _conversation.dispose();
    _surfaceController.dispose();
    _transport.dispose();
    super.dispose();
  }
}
