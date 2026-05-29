// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:genkit/genkit.dart' as genkit;
import 'package:genui/genui.dart';
import 'package:genui_express/genui_express.dart';
import 'package:logging/logging.dart';

import 'primitives/app_mode.dart';
import 'primitives/climbing/a2ui_components/climbing.dart';
import 'primitives/message.dart';

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
IMPORTANT: Always immediately display the matching climbing locations using the rich 'ClimbingLocation' component card in your response. Do not ask the user for more information, preferences, or clarification first. Show the best matches (like beginner-friendly locations) immediately in A2UI Express syntax.
IMPORTANT: You MUST surround the entire A2UI Express layout DSL block with the sentinel tags '<a2ui>' and '</a2ui>' to separate it from your conversational explanation.

Available Climbing Locations (use these exact identifiers in ClimbingLocation):
- 'kraft_boulders': Kraft Boulders (Outdoor, Free, Bouldering, Beginner/Intermediate/Advanced)
- 'calico_hills_i': Calico Hills I (Outdoor, Paid, Lead/Top Rope, Beginner/Intermediate)
- 'willow_springs': Willow Springs (Outdoor, Paid, Lead/Bouldering, Beginner/Intermediate)
- 'origin_climbing_fitness': Origin Climbing + Fitness (Indoor, Paid, Bouldering/Lead/Top Rope, Beginner/Intermediate/Advanced)
- 'the_refuge_climbing_center': The Refuge Climbing Center (Indoor, Paid, Bouldering, Beginner/Intermediate/Advanced)
- 'red_rock_climbing_center': Red Rock Climbing Center (Indoor, Paid, Lead/Top Rope/Bouldering, Beginner/Intermediate/Advanced)
- 'lone_mountain': Lone Mountain (Outdoor, Free, Lead, Beginner/Intermediate)

When the user asks about climbing locations, you must choose the most appropriate location identifiers matching their query (e.g., beginner-friendly, indoor/outdoor, bouldering, free/paid) and display them.
Always use the component named '${climbingLocationItem.name}' with the chosen identifier to display each location.
You must compose the final layout tree under the reserved 'root' variable using Column or Row to hold the location components.
Do not add any extra submit or confirmation buttons next to '${climbingLocationItem.name}' since it already contains a 'Learn more' button.

Example:
<a2ui>
root = Column([loc1, loc2])
loc1 = ClimbingLocation("kraft_boulders")
loc2 = ClimbingLocation("lone_mountain")
</a2ui>

When the user clicks 'Learn more' on a '${climbingLocationItem.name}', a UI action named 'learnMoreAboutLocation' will be sent with the location's identifier and name in its context. Respond with detailed information about that specific location.
''';
}

final Catalog _basicCatalog = BasicCatalogItems.asNoAssetCatalog(
  systemPromptFragments: [Prompts.choicePicker, Prompts.textFieldFallback],
);

final Catalog _customCatalog = _basicCatalog.copyWith(
  systemPromptFragments: [
    Prompts.climbingLocations,
    ..._basicCatalog.systemPromptFragments,
  ],
  newItems: [climbingLocationItem],
);

sealed class ChatSession extends ChangeNotifier {
  ChatSession._();

  factory ChatSession({
    genkit.Genkit? ai,
    genkit.ModelRef<dynamic>? model,
    required AppMode mode,
  }) {
    final genkit.Genkit effectiveAi = ai ?? genkit.Genkit(isDevEnv: false);
    if (ai == null) {
      GenuiExpressLocalModels.register(effectiveAi);
    }
    final genkit.ModelRef<Object?> effectiveModel =
        model ??
        (kIsWeb
            ? genkit.modelRef(GenuiExpressLocalModels.appleFoundationModels)
            : genkit.modelRef(GenuiExpressLocalModels.httpCompletion));

    return switch (mode) {
      AppMode.customCatalog => A2uiChatSession(
        ai: effectiveAi,
        model: effectiveModel,
        catalog: _customCatalog,
      ),
      AppMode.basicCatalog => A2uiChatSession(
        ai: effectiveAi,
        model: effectiveModel,
        catalog: _basicCatalog,
      ),
      AppMode.textOnly => TextOnlyChatSession(
        ai: effectiveAi,
        model: effectiveModel,
      ),
    };
  }

  final List<Message> _messages = [];
  List<Message> get messages => _messages;

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
    _logger.severe('Error in conversation: $error', error);
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
      _logger.severe(
        'Error sending request: $exception',
        exception,
        stackTrace,
      );
      _reportError(exception, showInChat: true);
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
}

/// A chat session that only supports text messages.
class TextOnlyChatSession extends ChatSession {
  TextOnlyChatSession({
    required genkit.Genkit ai,
    required genkit.ModelRef<dynamic> model,
  }) : _ai = ai,
       _model = model,
       super._() {
    _messagesHistory.add(
      genkit.Message(
        role: genkit.Role.system,
        content: [genkit.TextPart(text: Prompts.summary)],
      ),
    );
  }

  final genkit.Genkit _ai;
  final genkit.ModelRef<dynamic> _model;
  final List<genkit.Message> _messagesHistory = [];

  @override
  Future<void> sendMessage(String text) async {
    if (text.isEmpty) return;

    _currentAiMessage = null;
    _addUserMessage(text);

    await _runRequest(() async {
      _messagesHistory.add(
        genkit.Message(
          role: genkit.Role.user,
          content: [genkit.TextPart(text: text)],
        ),
      );

      final Stream<genkit.GenerateResponseChunk<dynamic>> stream = _ai
          .generateStream<dynamic, dynamic>(
            model: _model,
            messages: _messagesHistory,
          );

      final buffer = StringBuffer();
      await for (final chunk in stream) {
        if (chunk.text.isNotEmpty) {
          buffer.write(chunk.text);
          _updateAiMessage(chunk.text);
        }
      }

      _messagesHistory.add(
        genkit.Message(
          role: genkit.Role.model,
          content: [genkit.TextPart(text: buffer.toString())],
        ),
      );
    });
  }
}

/// A chat session that supports generative UI.
class A2uiChatSession extends ChatSession {
  A2uiChatSession({
    required genkit.Genkit ai,
    required genkit.ModelRef<dynamic> model,
    required Catalog catalog,
  }) : _catalog = catalog,
       super._() {
    _transport = ExpressLocalTransport(ai: ai, model: model, catalog: catalog);
    _surfaceController = SurfaceController(catalogs: [catalog]);
    _init();
  }

  final Catalog _catalog;

  late final ExpressLocalTransport _transport;
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

    _transport.addSystemMessage(
      ExpressPromptBuilder.chat(
        catalog: _catalog,
        systemPromptFragments: [
          Prompts.summary,
          PromptFragments.acknowledgeUser(),
          PromptFragments.requireAtLeastOneSubmitElement(
            prefix: PromptBuilder.defaultImportancePrefix,
          ),
        ],
      ).systemPromptJoined(),
    );
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

    // Doctor the prompt for local Gemini Nano to strongly adhere
    // to layout generation.
    final doctoredText =
        '$text\n\n'
        'IMPORTANT: You MUST output the user interface using the compact '
        'A2UI Express DSL notation. '
        'You MUST surround the entire A2UI Express DSL block with the '
        'sentinel tags `<a2ui>` and `</a2ui>` '
        'to separate it from your conversational explanation.\n\n'
        'CRITICAL: For "ClimbingLocation", you MUST ONLY pass the '
        'identifier string (e.g. "kraft_boulders") as a single positional '
        'argument. Do NOT define any other properties like name, description, '
        'difficulty, type, distance_from_lv, or coordinates inside the '
        'ClimbingLocation constructor!\n\n'
        'Correct Example:\n'
        '<a2ui>\n'
        'root = Column([loc1, loc2])\n'
        'loc1 = ClimbingLocation("kraft_boulders")\n'
        'loc2 = ClimbingLocation("lone_mountain")\n'
        '</a2ui>';

    await _runRequest(
      () => _transport.sendRequest(ChatMessage.user(doctoredText)),
    );
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
