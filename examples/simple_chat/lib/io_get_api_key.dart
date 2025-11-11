// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

/// API key for Google Generative AI (only needed if using google backend).
/// Get an API key from https://aistudio.google.com/app/apikey
const String googleApiKey = String.fromEnvironment('GEMINI_API_KEY');

String getApiKey() {
  var apiKey = googleApiKey.isEmpty
      ? Platform.environment['GOOGLE_API_KEY'] ?? ''
      : googleApiKey;
  if (apiKey.isEmpty) {
    throw Exception(
      '''Google API key is required when using google backend. Run the app with a GOOGLE_API_KEY as a Dart environment variable, for example by running with -D GEMINI_API_KEY=\$GEMINI_API_KEY or set the GEMINI_API_KEY environment variable in your shell environment.''',
    );
  }
  return apiKey;
}
