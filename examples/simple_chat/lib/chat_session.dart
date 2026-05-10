// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';
import 'package:logging/logging.dart';

import 'a2ui_transport.dart';
import 'agent/agent.dart';
import 'agent/ai_client.dart';
import 'message.dart';
import 'primitives/app_mode.dart';
import 'primitives/climbing/a2ui_components/climbing.dart';

export 'agent/ai_client.dart' show AiClient;

final Catalog _basicCatalog = BasicCatalogItems.asNoAssetCatalog(
  systemPromptFragments: [
    '''
When you need additional information from the user, try to use the component '${BasicCatalogItems.choicePicker.name}' to ask for it.
''',
    '''
If there is no way to itemize all the options, either use the component '${BasicCatalogItems.textField.name}' or add option 'Other' to the '${BasicCatalogItems.choicePicker.name}'.
''',
  ],
);

final Catalog _customCatalog = _basicCatalog.copyWith(
  systemPromptFragments: [
    '''
When you need additional information from the user, try to use the component '${BasicCatalogItems.choicePicker.name}' to ask for it.

**IMPORTANT**
If the user is asking about climbing locations, use the 'listClimbingLocations' tool to get a list of climbing locations.
Always use the component named '${climbingLocationItem.name}' to display the locations. The '${climbingLocationItem.name}' component already includes a 'Learn more' button; do not add any extra submit/confirmation buttons next to it.
When the user clicks 'Learn more' on a '${climbingLocationItem.name}', a UI action named 'learnMoreAboutLocation' will be sent with the location's identifier and name in its context. Respond with detailed information about that specific location.

**IMPORTANT**
When user asks about climbing locations, never use other components.
''',
    ..._basicCatalog.systemPromptFragments,
  ],
  newItems: [climbingLocationItem],
);

final PromptBuilder _promptBuilder = PromptBuilder.chat(
  catalog: _basicCatalog,
  systemPromptFragments: [
    _textOnlySystemPrompt,
    PromptFragments.acknowledgeUser(),
    PromptFragments.requireAtLeastOneSubmitElement(
      prefix: PromptBuilder.defaultImportancePrefix,
    ),
    PromptFragments.uiGenerationRestriction(
      prefix: PromptBuilder.defaultImportancePrefix,
    ),
  ],
);

const String _textOnlySystemPrompt =
    'You are a helpful assistant who chats with a user.';

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
    _agent.addSystemMessage(_textOnlySystemPrompt);
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
  A2uiChatSession({AiClient? aiClient, required Catalog catalog}) : super._() {
    _transport = SimpleChatA2aTransport(aiClient: aiClient);
    _surfaceController = SurfaceController(catalogs: [catalog]);
    _init();
  }

  late final SimpleChatA2aTransport _transport;
  late final SurfaceController _surfaceController;

  @override
  SurfaceController get surfaceController => _surfaceController;

  late final StreamSubscription<A2uiMessage> _messageSub;
  late final StreamSubscription<String> _textSub;
  late final StreamSubscription<ChatMessage> _submitSub;
  late final StreamSubscription<SurfaceUpdate> _surfaceSub;

  void _init() {
    _messageSub = _transport.incomingMessages.listen(
      _surfaceController.handleMessage,
    );
    _textSub = _transport.incomingText.listen(_updateAiMessage);
    _submitSub = _surfaceController.onSubmit.listen(
      (message) => _runRequest(() => _transport.sendRequest(message)),
    );
    _surfaceSub = _surfaceController.surfaceUpdates.listen(_onSurfaceUpdate);

    _transport.addSystemMessage(_promptBuilder.systemPromptJoined());
  }

  void _onSurfaceUpdate(SurfaceUpdate update) {
    switch (update) {
      case SurfaceAdded(:final surfaceId):
        _addSurfaceMessage(surfaceId);
      case SurfaceRemoved(:final surfaceId):
        _reportError('Surface $surfaceId removed', showInChat: false);
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
