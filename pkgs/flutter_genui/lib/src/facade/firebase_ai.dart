// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/widgets.dart';

/// Facade for the Flutter Gen UI package, tailored for Firebase AI integration.
class GenUiForFirebaseAi {
  GenUiForFirebaseAi({
    required ChatSession chatSession,
    String? generalPrompt,
    Object? widgetCatalog,
    Object? imageStore,
  });

  /// Renders the response from the model.
  ///
  /// Returns a [WidgetBuilder] that can be used to build the UI.
  ///
  /// The [prompt] parameter is the user prompt to be sent to the model.

  Future<GenUiBuilder> requestUi(String prompt) async {
    throw UnimplementedError(
      'The widgetBuilder getter is not implemented yet.',
    );
  }
}

/// A builder function for generating UI components.
///
/// The [onSubmit] and [onChange] callback is called when the user
/// submits or changes the selections
/// in the UI.
///
/// Some components may not require user interaction, in which case the
/// [onChange] and [onSubmit] callback will be never called.
typedef GenUiBuilder =
    Widget Function({
      UserSelection? selection,
      BuildContext? context,
      ValueChanged<UserSelection> onChange,
      VoidCallback onSubmit,
    });

abstract class UserSelection {}
