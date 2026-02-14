// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;
import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';

import 'ai_client.dart';
import 'message.dart';

/// A class that manages the chat session state and logic.
class ChatSession extends ChangeNotifier {
  ChatSession({required AiClient aiClient}) : _aiClient = aiClient {
    _init();
  }

  final AiClient _aiClient;

  final List<Message> _messages = [];
  List<Message> get messages => List.unmodifiable(_messages);

  late final SurfaceController _surfaceController;
  SurfaceHost get surfaceController => _surfaceController;

  late final A2uiTransportAdapter _transportAdapter;
  A2uiTransportAdapter get transportAdapter => _transportAdapter;

  final List<dartantic.ChatMessage> _chatHistory = [];

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  void _init() {
    final Catalog catalog = BasicCatalogItems.asCatalog();

    // Initialize Message Processor
    _surfaceController = SurfaceController(catalogs: [catalog]);

    // Initialize A2uiTransportAdapter
    _transportAdapter = A2uiTransportAdapter();

    // Wire controller to processor
    _transportAdapter.incomingMessages.listen(_surfaceController.handleMessage);

    // Listen to UI state updates from the processor
    _surfaceController.surfaceUpdates.listen((SurfaceUpdate update) {
      if (update is SurfaceAdded) {
        // Check if we already have a message with this surfaceId
        final bool exists = _messages.any(
          (m) => m.surfaceId == update.surfaceId,
        );

        if (!exists) {
          _messages.add(
            Message(isUser: false, text: null, surfaceId: update.surfaceId),
          );
          notifyListeners();
        }
      }
    });

    // Listen to client events (interactions) from the UI
    _surfaceController.onSubmit.listen(_handleChatMessage);

    final promptBuilder = PromptBuilder.chat(
      catalog: catalog,
      instructions:
          'You are a helpful assistant who chats with a user. '
          'Your responses should contain acknowledgment of the user message.',
    );

    // Add system instruction to history
    _chatHistory.add(dartantic.ChatMessage.system(promptBuilder.systemPrompt));
  }

  void _handleChatMessage(ChatMessage event) {
    genUiLogger.info('Received chat message: ${event.toJson()}');
    final buffer = StringBuffer();
    for (final dartantic.StandardPart part in event.parts) {
      if (part.isUiInteractionPart) {
        buffer.write(part.asUiInteractionPart!.interaction);
      } else if (part is TextPart) {
        buffer.write(part.text);
      }
    }
    final text = buffer.toString();
    if (text.isNotEmpty) {
      _sendInteraction(text);
    }
  }

  Future<void> _sendInteraction(String text) async {
    _chatHistory.add(dartantic.ChatMessage.user(text));
    await _performGeneration(text);
  }

  Future<void> sendMessage(String text) async {
    if (text.isEmpty) return;

    _messages.add(Message(isUser: true, text: 'You: $text'));
    _chatHistory.add(dartantic.ChatMessage.user(text));

    await _performGeneration(text);
  }

  Future<void> _performGeneration(String prompt) async {
    _isProcessing = true;
    notifyListeners();

    try {
      var fullResponseText = '';

      // Create a message controller for the AI response
      final aiMessageController = Message(isUser: false, text: 'AI: ');
      _messages.add(aiMessageController);
      notifyListeners();

      // Listen for text updates from the controller to update the UI
      final StreamSubscription<String> subscription = _transportAdapter
          .incomingText
          .listen((chunk) {
            aiMessageController.text = (aiMessageController.text ?? '') + chunk;
            notifyListeners();
          });

      // Use sendStream() to receive chunks of the response.
      final Stream<String> stream = _aiClient.sendStream(
        prompt,
        history: List.of(_chatHistory),
      );

      await for (final String chunk in stream) {
        if (chunk.isNotEmpty) {
          fullResponseText += chunk;
          _transportAdapter.addChunk(chunk);
        }
      }

      await subscription.cancel();

      _chatHistory.add(dartantic.ChatMessage.model(fullResponseText));
    } catch (exception, stackTrace) {
      genUiLogger.severe('Error generating content', exception, stackTrace);
      // We might want to expose errors via a listener or separate stream
      // For now, let's just log it. In a real app, we'd handle error states.
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _surfaceController.dispose();
    _transportAdapter.dispose();
    _aiClient.dispose();
    super.dispose();
  }
}
