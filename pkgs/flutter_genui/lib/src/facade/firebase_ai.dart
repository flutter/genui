// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_ai/firebase_ai.dart' as fb;
import 'package:flutter/widgets.dart';

import '../ai_client/gemini_ai_client.dart';
import '../core/genui_manager.dart';

class SimpleChat {
  late final GenUiManager _genUi;

  SimpleChat({
    required fb.ChatSession firebaseChatSession,
    String? generalPrompt,
    Object? widgetCatalog,
  }) {
    GeminiAiClient geminiAiClient = GeminiAiClient();
    _genUi = GenUiManager(
      aiClient: GeminiAiClient(systemInstruction: generalPrompt,modelCreator: () => firebaseChatSession.,
      ),
    );
  }

  Future<WidgetBuilder> sendTextRequest(String prompt) async {
    throw UnimplementedError();
  }
}
