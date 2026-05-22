// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;

import '../primitives/climbing/climbing_db.dart';
import 'api_key/api_key.dart';

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
    final String key = apiKey();
    _provider = dartantic.GoogleProvider(apiKey: key);
    _agent = dartantic.Agent.forProvider(
      _provider,
      chatModelName: modelName ?? 'gemini-3-flash-preview',
      tools: [
        dartantic.Tool(
          name: 'listClimbingLocations',
          description: 'Lists all available climbing locations.',
          onCall: (args) => climbingLocations.map((e) => e.toJson()).toList(),
        ),
      ],
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
    // Dartantic Agent/Provider doesn't strictly require disposal currently.
  }
}

/// A local Gemma 4 / OpenAI-compatible completions client.
class GemmaLocalAiClient implements AiClient {
  final String baseUrl;
  final String modelName;

  GemmaLocalAiClient({
    this.baseUrl = 'http://localhost:8080/v1',
    this.modelName = 'mlx-community/gemma-4-e2b-it-4bit',
  });

  @override
  Stream<String> sendStream(
    String prompt, {
    required List<dartantic.ChatMessage> history,
  }) async* {
    final client = HttpClient();
    try {
      final Uri uri = Uri.parse('$baseUrl/chat/completions');
      final HttpClientRequest request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;

      // Build OpenAI-compatible messages history
      final messagesPayload = <Map<String, String>>[];
      for (final msg in history) {
        var role = 'user';
        if (msg.role == dartantic.ChatMessageRole.system) {
          role = 'system';
        } else if (msg.role == dartantic.ChatMessageRole.model) {
          role = 'assistant';
        }
        messagesPayload.add({
          'role': role,
          'content': msg.text,
        });
      }
      
      // Add final user prompt if not already in history
      if (history.isEmpty || history.last.text != prompt) {
        messagesPayload.add({
          'role': 'user',
          'content': prompt,
        });
      }

      final Map<String, Object> payload = {
        'model': modelName,
        'messages': messagesPayload,
        'temperature': 0.1,
        'stream': true,
      };

      request.write(jsonEncode(payload));
      final HttpClientResponse response = await request.close();

      if (response.statusCode != 200) {
        final String body = await response.transform(utf8.decoder).join();
        throw HttpException(
          'Failed to connect to local model server: '
          '${response.statusCode}\n$body',
        );
      }

      // Parse Server-Sent Events (SSE) stream
      final Stream<String> lines = response
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final String line in lines) {
        if (line.startsWith('data: ')) {
          final String data = line.substring(6).trim();
          if (data == '[DONE]') {
            break;
          }
          try {
            final parsed = jsonDecode(data) as Map<String, Object?>;
            final choices = parsed['choices'] as List<Object?>?;
            final firstChoice = choices?.firstOrNull as Map<String, Object?>?;
            final delta = firstChoice?['delta'] as Map<String, Object?>?;
            final content = delta?['content'] as String?;
            if (content != null && content.isNotEmpty) {
              yield content;
            }
          } catch (_) {
            // Ignore parse failures on non-JSON SSE comments
          }
        }
      }
    } finally {
      client.close();
    }
  }

  @override
  void dispose() {}
}
