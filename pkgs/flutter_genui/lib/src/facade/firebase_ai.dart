// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_ai/firebase_ai.dart' as fb;
import 'package:flutter/widgets.dart';

/// Facade for the Flutter Gen UI package, tailored for Firebase AI integration.
class GenUiForFirebaseAi {
  GenUiForFirebaseAi({
    required fb.ChatSession firebaseChatSession,
    String? generalPrompt,
    Object? widgetCatalog,
    Object? imageStore,
  });

  Future<GenUiResponse> sendTextRequest(String prompt) async {
    throw UnimplementedError();
  }

  Future<GenUiResponse> sendRequestFromGenUi(UserSelection prompt) async {
    throw UnimplementedError();
  }

  /// Subscribes to changes in the widgets in previous Gen UI response.
  ///
  /// Use [GenUiResponse.responseId] to identify the previous widget
  /// that has changed.
  void listenPreviousWidgetChanges(ValueChanged<GenUiResponse> onChange) {
    throw UnimplementedError();
  }
}

class GenUiResponse {
  final GenUiBuilder builder;
  final String responseId;

  GenUiResponse({required this.builder, required this.responseId});
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
