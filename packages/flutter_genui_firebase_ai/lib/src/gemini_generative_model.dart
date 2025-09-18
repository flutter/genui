// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_ai/firebase_ai.dart';

/// An interface for a generative model, allowing for mock implementations.
///
/// This interface abstracts the underlying generative model, allowing for
/// different implementations to be used, for example, in testing.
abstract class GeminiGenerativeModelInterface {
  /// Generates content from the given [content].
  Future<GenerateContentResponse> generateContent(Iterable<Content> content);
}

/// A wrapper for the `firebase_ai` [GenerativeModel] that implements the
/// [GeminiGenerativeModelInterface].
///
/// This class is used to wrap the `firebase_ai` [GenerativeModel] so that it
/// can be used interchangeably with other implementations of the
/// [GeminiGenerativeModelInterface].
class GeminiGenerativeModel implements GeminiGenerativeModelInterface {
  /// Creates a new [GeminiGenerativeModel] that wraps the given [_model].
  GeminiGenerativeModel(this._model);

  final GenerativeModel _model;

  @override
  Future<GenerateContentResponse> generateContent(Iterable<Content> content) {
    return _model.generateContent(content);
  }
}
