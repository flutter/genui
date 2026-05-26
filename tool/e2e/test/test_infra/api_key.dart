// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

const geminiApiKeyName = 'GEMINI_API_KEY';

/// API key for Google Generative AI (only needed if using google backend).
/// Get an API key from https://aistudio.google.com/app/apikey
/// Specify this when running the app with "-D GEMINI_API_KEY=$GEMINI_API_KEY"
const String geminiApiKey = String.fromEnvironment(geminiApiKeyName);

String apiKeyForEval() {
  String apiKey = geminiApiKey;
  if (apiKey.isEmpty) {
    apiKey = Platform.environment[geminiApiKeyName] ?? '';
  }

  if (apiKey.isEmpty) {
    throw Exception('$geminiApiKeyName is not configured.');
  }
  return apiKey;
}
