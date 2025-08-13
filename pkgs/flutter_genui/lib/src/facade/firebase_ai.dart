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
  ///   ///
  /// The [onSubmit] callback is called when the user submits the selections
  /// in the UI.
  ///
  /// Some responses may not require user interaction, in which case the
  /// [onSubmit] callback will be never called.
  Future<WidgetBuilder> request(
    String prompt,
    ValueChanged<String> onSubmit,
  ) async {
    throw UnimplementedError(
      'The widgetBuilder getter is not implemented yet.',
    );
  }
}
