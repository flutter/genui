import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../ai_client/ai_client.dart';
import '../../core/new_genui_manager.dart';
import '../../model/catalog.dart';

class SimpleChatGenUi {
  SimpleChatGenUi({
    required AiClient aiClient,
    this.onWarning,
    Catalog? catalog,
    required String generalPrompt,
  }) {
    _genUi = NewGenUiManager(
      aiClient: aiClient,
      onWarning: onWarning,
      // TODO: extend default catalog with the widget for the chat surface
      // named "InteractiveChatMessage".
      catalog: catalog,
      generalPrompt: _generalPrompt(generalPrompt),
      surfaces: const GenUiSurfaces.empty(),
    );

    _streamSubscription = _genUi.allSurfaceUpdates.listen(_onUiReceived);
  }

  late _ChatSurface _chatSurface;

  late final StreamSubscription<SurfaceUpdate> _streamSubscription;

  late final NewGenUiManager _genUi;

  /// Called when there is a warning to report.
  final ValueChanged<GenUiWarning>? onWarning;

  /// If true, the AI is processing a request.
  ValueListenable<bool> get isProcessing => _genUi.isProcessing;

  void _onUiReceived(SurfaceUpdate update) {
    if (update.surfaceId != _chatSurface.surfaceId) {
      onWarning?.call(
        TextGenUiWarning(
          'Received update for surface "${update.surfaceId}", '
          'but this surface does not exist any more.'
          'The current chat surface is "${_chatSurface.surfaceId}".',
        ),
      );
      return;
    }
    _chatSurface.onUpdate(update.builder);
  }

  /// Sends a text prompt to the AI client.
  ///
  /// Returns the UI to show to the user.
  void sendTextPrompt(String prompt, ValueChanged<WidgetBuilder> onUpdate) {
    _chatSurface = _ChatSurface(onUpdate);
    _genUi.surfaces = _chatSurface.surfaces;
    // Unawaited because the builder will be provided in `onUpdate`.
    _genUi.sendTextPrompt(prompt);
  }

  void dispose() {
    _streamSubscription.cancel();
    _genUi.dispose();
  }
}

class _ChatSurface {
  static int _chatSurfaceIndex = 1;

  _ChatSurface(this.onUpdate) : surfaceId = 'chat${_chatSurfaceIndex++}';

  final ValueChanged<WidgetBuilder> onUpdate;

  final String surfaceId;

  late final GenUiSurfaces surfaces = GenUiSurfaces(
    surfacesIds: {surfaceId},
    description: _surfacesDescription(surfaceId),
  );
}

String _generalPrompt(String customization) {
  return '''You are a helpful AI assistant chats
with user, answering their questions and providing information.
You should respond to the user's requests in a conversational manner,
and you may ask for clarifications if needed.
You should not ask for clarifications if the user has already provided enough information.

The user has two ways to interact with you:
1. text prompts: sending text messages, which you should respond to.
2. non-text prompts: clicking on the buttons and selecting options you provide in your responses.

$customization
''';
}

String _surfacesDescription(String surfaceId) =>
    '''
The surface "$surfaceId" is intended to contain non-text interactions between you and the user and the AI in response to the last text prompt.

If you can respond to the user's request, just respond.

Otherwise, you should ask for clarifications or provide options for the user to choose from.

You should continue appending to the surface with new responses till the moment when the response does not require non-text input from the user, and you can just answer the question.
''';
