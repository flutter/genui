// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';
import 'package:logging/logging.dart';

import 'a2ui_transport.dart';
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
If the user is asking about climbing locations, use the 'listClimbingLocations' tool to get a list of climbing locations.
To render a climbing location use the widget 'ClimbingLocation'. The 'ClimbingLocation' widget already includes a 'Learn more' button; do not add any extra submit/confirmation buttons next to it.
When the user clicks 'Learn more' on a 'ClimbingLocation', a UI action named 'learnMoreAboutLocation' will be sent with the location's identifier and name in its context. Respond with detailed information about that specific location.
''',
    ..._basicCatalog.systemPromptFragments,
  ],
  newItems: [climbingLocationItem],
);

final PromptBuilder _promptBuilder = PromptBuilder.chat(
  catalog: _basicCatalog,
  systemPromptFragments: [
    'You are a helpful assistant who chats with a user.',
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
}

/// A chat session that only supports text messages.
class TextOnlyChatSession extends ChatSession {
  TextOnlyChatSession({AiClient? aiClient}) : super._() {}
}

/// A chat session that supports generative UI.
class A2uiChatSession extends ChatSession {
  A2uiChatSession({AiClient? aiClient, required Catalog catalog}) : super._() {
    _transport = SimpleChatA2aTransport(aiClient: aiClient);
    surfaceController = SurfaceController(catalogs: [catalog]);
    _init();
  }

  late final SimpleChatA2aTransport _transport;
  late final SurfaceController surfaceController;

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  final List<Message> _messages = [];
  List<Message> get messages => List.unmodifiable(_messages);

  final Logger _logger = Logger('ChatSession');

  late final StreamSubscription<A2uiMessage> _messageSub;
  late final StreamSubscription<String> _textSub;
  late final StreamSubscription<ChatMessage> _submitSub;
  late final StreamSubscription<SurfaceUpdate> _surfaceSub;

  void _init() {
    _messageSub = _transport.incomingMessages.listen(
      surfaceController.handleMessage,
    );
    _textSub = _transport.incomingText.listen(_updateAiMessage);
    _submitSub = surfaceController.onSubmit.listen(_sendRequest);
    _surfaceSub = surfaceController.surfaceUpdates.listen(_onSurfaceUpdate);

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

  void _reportError(Object error, {required bool showInChat}) {
    _logger.severe('Error in conversation', error);
    if (showInChat) {
      _messages.add(Message(isUser: false, text: 'Error: $error'));
      notifyListeners();
    }
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
    notifyListeners();

    await _sendRequest(ChatMessage.user(text));
  }

  Future<void> _sendRequest(ChatMessage message) async {
    _isProcessing = true;
    notifyListeners();
    try {
      await _transport.sendRequest(message);
    } catch (exception, stackTrace) {
      _logger.severe('Error sending request', exception, stackTrace);
      _reportError(exception, showInChat: true);
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _messageSub.cancel();
    _textSub.cancel();
    _submitSub.cancel();
    _surfaceSub.cancel();
    surfaceController.dispose();
    _transport.dispose();
    super.dispose();
  }
}
