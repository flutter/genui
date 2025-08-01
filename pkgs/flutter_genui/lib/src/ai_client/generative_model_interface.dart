// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_ai/firebase_ai.dart';

/// An interface for a generative model, allowing for mock implementations.
abstract class GenerativeModelInterface {
  Future<GenerateContentResponse> generateContent(
    Iterable<Content> content, {
    List<SafetySetting>? safetySettings,
    GenerationConfig? generationConfig,
    List<Tool>? tools,
    ToolConfig? toolConfig,
  });
}

/// A wrapper for the `firebase_ai` [GenerativeModel] that implements the
/// [GenerativeModelInterface].
class GenerativeModelWrapper implements GenerativeModelInterface {
  final GenerativeModel _model;

  GenerativeModelWrapper(this._model);

  @override
  Future<GenerateContentResponse> generateContent(
    Iterable<Content> content, {
    List<SafetySetting>? safetySettings,
    GenerationConfig? generationConfig,
    List<Tool>? tools,
    ToolConfig? toolConfig,
  }) {
    return _model.generateContent(
      content,
      safetySettings: safetySettings,
      generationConfig: generationConfig,
      tools: tools,
      toolConfig: toolConfig,
    );
  }
}
