// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Enum for selecting which AI backend to use.
enum AiBackend {
  /// Use Firebase AI
  firebase,

  /// Use Google Generative AI
  googleGenerativeAi,
}

/// Configuration for which AI backend to use.
/// Change this value to switch between backends.
const AiBackend aiBackend = AiBackend.googleGenerativeAi;
