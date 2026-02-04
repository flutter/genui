// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;
import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';

import 'api_key/io_get_api_key.dart'
    if (dart.library.html) 'api_key/web_get_api_key.dart';
import 'message.dart';

/// A class that manages the chat session state and logic.
class ChatSession extends ChangeNotifier {
  ChatSession() {
    _init();
  }

  final List<MessageController> _messages = [];
  List<MessageController> get messages => List.unmodifiable(_messages);

  late final A2uiMessageProcessor _messageProcessor;
  GenUiHost get genUiContext => _messageProcessor;

  late final GenUiController _genUiController;
  GenUiController get genUiController => _genUiController;

  late final dartantic.GoogleProvider _provider;
  late final dartantic.Agent _agent;
  final List<dartantic.ChatMessage> _chatHistory = [];

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  void _init() {
    final Catalog catalog = CoreCatalogItems.asCatalog();

    // Initialize Message Processor
    _messageProcessor = A2uiMessageProcessor(catalogs: [catalog]);

    // Initialize GenUiController
    _genUiController = GenUiController();

    // Wire controller to processor
    _genUiController.messageStream.listen(_messageProcessor.handleMessage);

    // Listen to UI state updates from the processor
    _messageProcessor.surfaceUpdates.listen((update) {
      if (update is SurfaceAdded) {
        // Check if we already have a message with this surfaceId
        final bool exists = _messages.any(
          (m) => m.surfaceId == update.surfaceId,
        );

        if (!exists) {
          _messages.add(
            MessageController(
              isUser: false,
              text: null,
              surfaceId: update.surfaceId,
            ),
          );
          notifyListeners();
        }
      }
    });

    // Listen to client events (interactions) from the UI
    _messageProcessor.onSubmit.listen(_handleChatMessage);

    final String a2uiSchema = A2uiMessage.a2uiMessageSchema(
      catalog,
    ).toJson(indent: '  ');

    final systemInstruction =
        '''You are a helpful assistant who chats with a user.
Your responses should contain acknowledgment of the user message.

IMPORTANT: When you generate UI in a response, you MUST always create
a new surface with a unique `surfaceId`. Do NOT reuse or update
existing `surfaceId`s. Each UI response must be in its own new surface.

<a2ui_schema>
$a2uiSchema
</a2ui_schema>

${StandardCatalogEmbed.standardCatalogRules}

${GenUiPromptFragments.basicChat}''';

    // Initialize Dartantic Provider and Agent
    final String apiKey = getApiKey();

    _provider = dartantic.GoogleProvider(apiKey: apiKey);

    _agent = dartantic.Agent.forProvider(
      _provider,
      chatModelName: 'gemini-3-flash-preview',
    );

    // Add system instruction to history
    _chatHistory.add(dartantic.ChatMessage.system(systemInstruction));
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

    _messages.add(MessageController(isUser: true, text: 'You: $text'));
    _chatHistory.add(dartantic.ChatMessage.user(text));

    await _performGeneration(text);
  }

  Future<void> _performGeneration(String prompt) async {
    _isProcessing = true;
    notifyListeners();

    try {
      var fullResponseText = '';

      // Create a message controller for the AI response
      final aiMessageController = MessageController(
        isUser: false,
        text: 'AI: ',
      );
      _messages.add(aiMessageController);
      notifyListeners();

      // Listen for text updates from the controller to update the UI
      final StreamSubscription<String> subscription = _genUiController
          .textStream
          .listen((chunk) {
            aiMessageController.text = (aiMessageController.text ?? '') + chunk;
            notifyListeners();
          });

      // Use sendStream() to receive chunks of the response.
      final Stream<dartantic.ChatResult<String>> stream = _agent.sendStream(
        prompt,
        history: List.of(_chatHistory),
      );

      await for (final result in stream) {
        final String chunk = result.output;
        if (chunk.isNotEmpty) {
          fullResponseText += chunk;
          _genUiController.addChunk(chunk);
        }
      }

      await subscription.cancel();

      _chatHistory.add(dartantic.ChatMessage.model(fullResponseText));
    } catch (e, st) {
      genUiLogger.severe('Error generating content', e, st);
      // We might want to expose errors via a listener or separate stream
      // For now, let's just log it. In a real app, we'd handle error states.
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _messageProcessor.dispose();
    _genUiController.dispose();
    super.dispose();
  }
}
