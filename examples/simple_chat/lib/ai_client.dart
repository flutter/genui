// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;

import 'api_key/io_get_api_key.dart'
    if (dart.library.html) 'api_key/web_get_api_key.dart';

/// An abstract interface for AI clients.
abstract interface class AiClient {
  /// Sends a message stream request to the AI service.
  ///
  /// [prompt] is the user's message.
  /// [history] is the conversation history.
  Stream<String> sendStream(
    String prompt, {
    required List<dartantic.ChatMessage> history,
  });

  /// Dispose of resources.
  void dispose();
}

/// An implementation of [AiClient] using `package:dartantic_ai`.
class DartanticAiClient implements AiClient {
  DartanticAiClient({String? modelName}) {
    final String apiKey = getApiKey();
    _provider = dartantic.GoogleProvider(apiKey: apiKey);
    _agent = dartantic.Agent.forProvider(
      _provider,
      chatModelName: modelName ?? 'gemini-3-flash-preview',
    );
  }

  late final dartantic.GoogleProvider _provider;
  late final dartantic.Agent _agent;

  @override
  Stream<String> sendStream(
    String prompt, {
    required List<dartantic.ChatMessage> history,
  }) async* {
    final Stream<dartantic.ChatResult<String>> stream = _agent.sendStream(
      prompt,
      history: history,
    );

    await for (final result in stream) {
      if (result.output.isNotEmpty) {
        yield result.output;
      }
    }
  }

  @override
  void dispose() {
    // Dartantic Agent/Provider doesn't strictly require disposal currently,
    // but good to have the hook.
  }
}
