// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_ai/firebase_ai.dart' as fb;
import 'package:flutter/widgets.dart';

import '../ai_client/gemini_ai_client.dart';
import '../core/genui_manager.dart';

/// Facade for the Flutter Gen UI package, tailored for Firebase AI integration.
class GenUiForFirebaseAi {
  late final GenUiManager _manager;
  final List<String> pinnedWidgets;

  GenUiForFirebaseAi({
    required fb.ChatSession firebaseChatSession,
    String? generalPrompt,
    Object? widgetCatalog,
    this.pinnedWidgets = const [],
  }) {
    // TODO: use the provided firebaseChatSession.
    _manager = GenUiManager(
      aiClient: GeminiAiClient(
        systemInstruction:
            '''You are a helpful assistant who speaks in the style of a pirate.

    The user will ask questions, and you will respond by generating appropriate UI elements. Typically, you will first elicit more information to understand the user's needs, then you will start displaying information and the user's plans.

    ''',
      ),
    );
  }

  Future<GenUiResponse> sendTextRequest(String prompt) async {
    throw UnimplementedError();
  }

  Future<GenUiResponse> sendRequestFromGenUi(UserSelection prompt) async {
    throw UnimplementedError();
  }
}

class GenUiResponse {
  final GenUiBuilder? chatMessage;
  final Map<String, GenUiBuilder> pinnedWidgets;

  GenUiResponse(this.chatMessage, this.pinnedWidgets);
}

/// A builder function for generating UI components.
///
/// The [onSubmitted] and [onChanged] callback is called when the user
/// submits or changes the selections
/// in the UI.
///
/// Some components may not require user interaction, in which case the
/// callbacks will be never called.
typedef GenUiBuilder =
    Widget Function({
      UserSelection? selection,
      BuildContext? context,
      ValueChanged<UserSelection> onChanged,
      ValueChanged<UserSelection> onSubmitted,
    });

abstract class UserSelection {}
