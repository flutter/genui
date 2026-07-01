// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:a2ui_core/a2ui_core.dart' as core;
import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';
import 'package:logging/logging.dart';

import 'a2ui_transport.dart';
import 'agent/agent.dart';
import 'agent/ai_client.dart';
import 'primitives/app_mode.dart';
import 'primitives/climbing/a2ui_components/climbing.dart';
import 'primitives/message.dart';

export 'agent/ai_client.dart' show AiClient;

/// System prompts used to configure the chat sessions in this example.
abstract final class Prompts {
  Prompts._();

  static const String summary =
      'You are a helpful assistant who chats with a user.';

  static final String choicePicker =
      '''
When you need additional information from the user, try to use the component '${BasicCatalogItems.choicePicker.name}' to ask for it.
''';

  static final String textFieldFallback =
      '''
If there is no way to itemize all the options, either use the component '${BasicCatalogItems.textField.name}' or add option 'Other' to the '${BasicCatalogItems.choicePicker.name}'.
''';

  static final String climbingLocations =
      '''
If the user is asking about climbing locations, use the 'listClimbingLocations' tool to get a list of climbing locations.
Always use the component named '${climbingLocationItem.name}' to display the locations. The '${climbingLocationItem.name}' component already includes a 'Learn more' button; do not add any extra submit/confirmation buttons next to it.
When the user clicks 'Learn more' on a '${climbingLocationItem.name}', a UI action named 'learnMoreAboutLocation' will be sent with the location's identifier and name in its context. Respond with detailed information about that specific location.

When user asks about climbing locations, never use other components.
''';
}

final Catalog _basicCatalog =
    BasicCatalogItems.asCatalog(
      systemPromptFragments: [Prompts.choicePicker, Prompts.textFieldFallback],
    ).copyWithout(
      itemsToRemove: [
        BasicCatalogItems.audioPlayer,
        BasicCatalogItems.image,
        BasicCatalogItems.video,
      ],
    );

final Catalog _customCatalog = _basicCatalog.copyWith(
  systemPromptFragments: [
    Prompts.climbingLocations,
    ..._basicCatalog.systemPromptFragments,
  ],
  newItems: [climbingLocationItem],
);

Future<PromptBuilder> _promptBuilderFor(Catalog catalog) async =>
    await PromptBuilder.createChat(
      catalog: catalog,
      systemPromptFragments: [
        Prompts.summary,
        PromptFragments.acknowledgeUser(),
        PromptFragments.requireAtLeastOneSubmitElement(
          prefix: PromptBuilder.defaultImportancePrefix,
        ),
        PromptFragments.uiGenerationRestriction(
          prefix: PromptBuilder.defaultImportancePrefix,
        ),
      ],
    );

sealed class ChatSession extends ChangeNotifier {
  ChatSession._();

  factory ChatSession({AiClient? aiClient, required AppMode mode}) {
    return switch (mode) {
      AppMode.customCatalog => A2uiChatSession(
        aiClient: aiClient,
        catalog: _customCatalog,
      ),
      AppMode.basicCatalog => A2uiChatSession(
        aiClient: aiClient,
        catalog: _basicCatalog,
      ),
      AppMode.textOnly => TextOnlyChatSession(aiClient: aiClient),
    };
  }

  final List<Message> _messages = [];
  List<Message> get messages => List.unmodifiable(_messages);

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  /// The surface host for rendering generative UI surfaces, or `null` if this
  /// session does not produce surfaces (e.g. text-only chat).
  SurfaceHost? get surfaceController => null;

  final Logger _logger = Logger('ChatSession');

  Message? _currentAiMessage;

  Future<void> sendMessage(String text);

  void _addUserMessage(String text) {
    _messages.add(Message(isUser: true, text: 'You: $text'));
    notifyListeners();
  }

  void _updateAiMessage(String chunk) {
    if (_currentAiMessage == null) {
      _currentAiMessage = Message(isUser: false, text: '');
      _messages.add(_currentAiMessage!);
    }
    _currentAiMessage!.text = (_currentAiMessage!.text ?? '') + chunk;
    notifyListeners();
  }

  void _reportError(Object error, {required bool showInChat}) {
    _logger.severe('Error in conversation', error);
    if (showInChat) {
      _messages.add(Message(isUser: false, text: 'Error: $error'));
      notifyListeners();
    }
  }

  Future<void> _runRequest(Future<void> Function() body) async {
    _isProcessing = true;
    notifyListeners();
    try {
      await body();
    } catch (exception, stackTrace) {
      _logger.severe('Error sending request', exception, stackTrace);
      _reportError(exception, showInChat: true);
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
}

/// A chat session that only supports text messages.
class TextOnlyChatSession extends ChatSession {
  TextOnlyChatSession({AiClient? aiClient}) : super._() {
    _agent = SimpleChatAgent(
      aiClient: aiClient,
      onChunkFromAgent: _updateAiMessage,
    );
    _agent.addSystemMessage(Prompts.summary);
  }

  late final SimpleChatAgent _agent;

  @override
  Future<void> sendMessage(String text) async {
    if (text.isEmpty) return;

    _currentAiMessage = null;
    _addUserMessage(text);

    await _runRequest(
      () => _agent.handleRequestFromRenderer(ChatMessage.user(text)),
    );
  }
}

/// A chat session that supports generative UI.
class A2uiChatSession extends ChatSession {
  A2uiChatSession({AiClient? aiClient, required Catalog catalog})
    : _catalog = catalog,
      super._() {
    _transport = SimpleChatA2aTransport(aiClient: aiClient);
    _surfaceController = SurfaceController(catalogs: [catalog]);
    _init();
  }

  final Catalog _catalog;

  late final SimpleChatA2aTransport _transport;
  late final SurfaceController _surfaceController;

  @override
  SurfaceController get surfaceController => _surfaceController;

  late final StreamSubscription<core.A2uiMessage> _messageSub;
  late final StreamSubscription<String> _textSub;
  late final StreamSubscription<ChatMessage> _submitSub;
  late final StreamSubscription<SurfaceUpdate> _surfaceSub;

  Future<void> _init() async {
    _messageSub = _transport.incomingMessages.listen(
      _surfaceController.handleMessage,
    );
    _textSub = _transport.incomingText.listen(_updateAiMessage);
    _submitSub = _surfaceController.onSubmit.listen(
      (message) => _runRequest(() => _transport.sendRequest(message)),
    );
    _surfaceSub = _surfaceController.surfaceUpdates.listen(_onSurfaceUpdate);

    final PromptBuilder pb = await _promptBuilderFor(_catalog);
    _transport.addSystemMessage(pb.systemPromptJoined());
  }

  void _onSurfaceUpdate(SurfaceUpdate update) {
    switch (update) {
      case SurfaceAdded(:final surfaceId):
        _addSurfaceMessage(surfaceId);
      case SurfaceRemoved(:final surfaceId):
        _reportError(
          'Surface $surfaceId removed, that should not happen in chat.',
          showInChat: false,
        );
      case ComponentsUpdated():
        break;
    }
  }

  void _addSurfaceMessage(String surfaceId) {
    final bool exists = _messages.any((m) => m.surfaceId == surfaceId);
    if (!exists) {
      _messages.add(Message(isUser: false, text: null, surfaceId: surfaceId));
      notifyListeners();
    }
  }

  @override
  Future<void> sendMessage(String text) async {
    if (text.isEmpty) return;

    // Reset current AI message so new response gets a new bubble
    _currentAiMessage = null;

    _addUserMessage(text);

    await _runRequest(() => _transport.sendRequest(ChatMessage.user(text)));
  }

  @override
  void dispose() {
    _messageSub.cancel();
    _textSub.cancel();
    _submitSub.cancel();
    _surfaceSub.cancel();
    _surfaceController.dispose();
    _transport.dispose();
    super.dispose();
  }
}
