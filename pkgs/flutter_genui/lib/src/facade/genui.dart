// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// Facade for the Flutter Gen UI package
class FlutterGenUI {
  FlutterGenUI.light({
    String? generalPrompt,
    Object? widgetCatalog,
    Object? imageStore,
    bool collectHistory = true,
  });

  /// Converts a general prompt into a prompt that requests to return UI.
  String uiPrompt(String prompt) {
    throw UnimplementedError('The uiPrompt method is not implemented yet.');
  }

  /// Renders the response from the model.
  ///
  /// The [response] is a string that describes the UI.
  /// The [onSubmit] callback is called when the user submits selections
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
