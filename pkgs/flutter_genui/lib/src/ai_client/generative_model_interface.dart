// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_ai/firebase_ai.dart';

/// An interface for a generative model, allowing for mock implementations.
///
/// This interface abstracts the underlying generative model, allowing for
/// different implementations to be used, for example, in testing.
abstract class GenerativeModelInterface {
  /// Generates content from the given [content].
  Future<GenerateContentResponse> generateContent(Iterable<Content> content);
}

/// A wrapper for the `firebase_ai` [GenerativeModel] that implements the
/// [GenerativeModelInterface].
///
/// This class is used to wrap the `firebase_ai` [GenerativeModel] so that it
/// can be used interchangeably with other implementations of the
/// [GenerativeModelInterface].
class FirebaseAiGenerativeModel implements GenerativeModelInterface {
  /// Creates a new [FirebaseAiGenerativeModel] that wraps the given [_model].
  FirebaseAiGenerativeModel(this._model);

  final GenerativeModel _model;

  @override
  Future<GenerateContentResponse> generateContent(Iterable<Content> content) {
    return _model.generateContent(content);
  }
}
