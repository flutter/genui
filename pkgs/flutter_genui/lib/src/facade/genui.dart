// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// Facade for the Flutter Gen UI package
class FlutterGenUI {
  FlutterGenUI({
    String? generalPrompt,
    Object? widgetCatalog,
    Object? imageStore,
  });

  /// Converts a general prompt to a prompt that requests to return UI.
  String uiPrompt(String prompt) {
    throw UnimplementedError('The uiPrompt method is not implemented yet.');
  }

  /// Renders the response from the model.
  ///
  /// The [response] is a string, received from AI, that describes the UI.
  /// The [onSubmit] callback is called when the user submits the selections
  /// in the UI.
  WidgetBuilder renderResponse(
    String response,
    ValueChanged<String>? onSubmit,
  ) {
    throw UnimplementedError(
      'The widgetBuilder getter is not implemented yet.',
    );
  }
}
