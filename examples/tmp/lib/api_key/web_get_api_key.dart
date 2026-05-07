// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// API key for Google Generative AI (only needed if using google backend).
/// Get an API key from https://aistudio.google.com/app/apikey
const String _geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

String? debugApiKey;

String getApiKey() {
  if (debugApiKey != null) {
    return debugApiKey!;
  }
  if (_geminiApiKey.isEmpty) {
    throw Exception(
      '''Gemini API key is required when using google backend. Run the app with a GEMINI_API_KEY as a Dart environment variable. You can do this by running with -D GEMINI_API_KEY=\$GEMINI_API_KEY''',
    );
  }
  return _geminiApiKey;
}
