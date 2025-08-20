// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import '../ai_client/ai_client.dart';
import '../core/new_genui_manager.dart';
import '../model/catalog.dart';

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
      catalog: catalog,
      generalPrompt: generalPrompt,
      surfaces: GenUiSurfaces.empty(),
    );
  }

  late final NewGenUiManager _genUi;

  /// Called when there is a warning to report.
  final ValueChanged<GenUiWarning>? onWarning;

  /// If true, the AI is processing a request.
  ValueListenable<bool> get isProcessing => _isProcessing;
  final ValueNotifier<bool> _isProcessing = ValueNotifier<bool>(false);
}
