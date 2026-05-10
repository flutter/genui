// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;
import 'package:flutter/widgets.dart';
import 'package:genui/genui.dart';
import 'package:logging/logging.dart';

import 'a2ui_components/climbing.dart';
import 'ai_client.dart';
import 'ai_client_transport.dart';
import 'message.dart';

final Catalog basicCatalog = BasicCatalogItems.asCatalog().copyWithout(
  itemsToRemove: [
    BasicCatalogItems.image,
    BasicCatalogItems.video,
    BasicCatalogItems.audioPlayer,
  ],
);

final Catalog customCatalog =
    BasicCatalogItems.asCatalog(
          systemPromptFragments: [
            '''
When you need additional information from the user, try to use the component '${BasicCatalogItems.choicePicker.name}' to ask for it.
If the user is asking about climbing locations, use the 'listClimbingLocations' tool to get a list of climbing locations.
To render a climbing location use the widget 'ClimbingLocation'. The 'ClimbingLocation' widget already includes a 'Learn more' button; do not add any extra submit/confirmation buttons next to it.
When the user clicks 'Learn more' on a 'ClimbingLocation', a UI action named 'learnMoreAboutLocation' will be sent with the location's identifier and name in its context. Respond with detailed information about that specific location.
''',
            '''
If there is no way to itemize all the options, either use the component '${BasicCatalogItems.textField.name}' or add option 'Other' to the '${BasicCatalogItems.choicePicker.name}'.
''',
          ],
        )
        .copyWithout(
          itemsToRemove: [
            BasicCatalogItems.image,
            BasicCatalogItems.video,
            BasicCatalogItems.audioPlayer,
          ],
        )
        .copyWith(newItems: [climbingLocationItem]);

PromptBuilder _promptBuilderFor(Catalog catalog) => PromptBuilder.chat(
  catalog: catalog,
  systemPromptFragments: [
    'You are a helpful assistant who chats with a user.',
    PromptFragments.acknowledgeUser(),
    PromptFragments.uiGenerationRestriction(
      prefix: PromptBuilder.defaultImportancePrefix,
    ),
    PromptFragments.preferUi(prefix: PromptBuilder.defaultImportancePrefix),
  ],
);

/// Common interface for the chat backends shown by the chat screen.
abstract base class ChatBackend extends ChangeNotifier {
  List<Message> get messages;
  bool get isProcessing;
  SurfaceHost? get surfaceController => null;
  ActionDelegate? get actionDelegate => null;
  Future<void> sendMessage(String text);
}

/// Intercepts UI actions (e.g. AI-generated button taps) and routes them back
/// into the owning [ChatSession] so they show up as user messages and get
/// forwarded to the LLM. Returning `true` from [handleEvent] short-circuits
/// the default surface-event routing, avoiding double-submission.
class _ChatActionDelegate implements ActionDelegate {
  _ChatActionDelegate(this._onUserAction);

  final void Function(UserActionEvent event) _onUserAction;

  @override
  bool handleEvent(
    BuildContext context,
    UiEvent event,
    SurfaceContext genUiContext,
    Widget Function(SurfaceDefinition, Catalog, String, DataContext)
    buildWidget,
  ) {
    if (event is! UserActionEvent) return false;
    _onUserAction(event);
    return true;
  }
}

/// A genui-backed chat session driven by a [Catalog].
final class ChatSession extends ChatBackend {
  ChatSession({required AiClient aiClient, required Catalog catalog}) {
    _transport = AiClientTransport(aiClient: aiClient);
    _surfaceController = SurfaceController(catalogs: [catalog]);
    conversation = Conversation(
      controller: _surfaceController,
      transport: _transport,
    );
    _actionDelegate = _ChatActionDelegate(_handleUserAction);
    _init(catalog);
  }

  late final AiClientTransport _transport;
  late final SurfaceController _surfaceController;
  late final Conversation conversation;
  late final _ChatActionDelegate _actionDelegate;

  @override
  SurfaceHost get surfaceController => _surfaceController;

  @override
  ActionDelegate get actionDelegate => _actionDelegate;

  @override
  bool get isProcessing => conversation.state.value.isWaiting;

  final List<Message> _messages = [];
  @override
  List<Message> get messages => List.unmodifiable(_messages);

  final Logger _logger = Logger('ChatSession');

  void _init(Catalog catalog) {
    conversation.state.addListener(notifyListeners);

    conversation.events.listen((event) {
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
        case ConversationComponentsUpdated(): // TODO: log error and add error handling to test
        case ConversationSurfaceRemoved(): // TODO: log error and add error handling to test
          break;
      }
    });

    _transport.addSystemMessage(
      _promptBuilderFor(catalog).systemPromptJoined(),
    );
  }

  /// Called by [_actionDelegate] when the user interacts with a generated
  /// component (e.g. taps an AI-rendered Button). The delegate returns `true`
  /// from `handleEvent`, so this is the only path the click takes — no
  /// double-submission via the controller's default forwarding.
  void _handleUserAction(UserActionEvent event) {
    _currentAiMessage = null;
    _messages.add(Message(isUser: true, text: 'You clicked: ${event.name}'));
    notifyListeners();

    final ChatMessage chatMessage = ChatMessage.user(
      '',
      parts: [
        UiInteractionPart.create(
          jsonEncode({'version': 'v0.9', 'action': event.toMap()}),
        ),
      ],
    );
    conversation.sendRequest(chatMessage);
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

  @override
  Future<void> sendMessage(String text) async {
    if (text.isEmpty) return;

    _currentAiMessage = null;

    _messages.add(Message(isUser: true, text: 'You: $text'));
    notifyListeners();

    final message = ChatMessage.user(text);
    await conversation.sendRequest(message);
  }

  @override
  void dispose() {
    conversation.dispose();
    _surfaceController.dispose();
    _transport.dispose();
    super.dispose();
  }
}

/// A plain text chat backend that talks to [AiClient] directly, bypassing
/// genui entirely.
final class TextOnlySession extends ChatBackend {
  TextOnlySession({required AiClient aiClient}) : _aiClient = aiClient;

  final AiClient _aiClient;
  final List<Message> _messages = [];
  final List<dartantic.ChatMessage> _history = [
    dartantic.ChatMessage.system(
      'You are a helpful assistant who chats with a user.',
    ),
  ];
  bool _isProcessing = false;
  final Logger _logger = Logger('TextOnlySession');

  @override
  List<Message> get messages => List.unmodifiable(_messages);

  @override
  bool get isProcessing => _isProcessing;

  @override
  Future<void> sendMessage(String text) async {
    if (text.isEmpty) return;

    _messages.add(Message(isUser: true, text: 'You: $text'));
    final aiMessage = Message(isUser: false, text: '');
    _messages.add(aiMessage);
    _isProcessing = true;
    notifyListeners();

    final response = StringBuffer();
    try {
      await for (final chunk in _aiClient.sendStream(
        text,
        history: List.of(_history),
      )) {
        response.write(chunk);
        aiMessage.text = response.toString();
        notifyListeners();
      }
      _history.add(dartantic.ChatMessage.user(text));
      _history.add(dartantic.ChatMessage.model(response.toString()));
    } catch (exception, stackTrace) {
      _logger.severe('Error sending request', exception, stackTrace);
      aiMessage.text = 'Error: $exception';
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
}
