// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:genkit/genkit.dart';

const _channel = MethodChannel('genui_express/local_ai');
const _eventChannel = EventChannel('genui_express/local_ai_stream');

/// Registers custom local on-device models with a [Genkit] instance.
class GenuiExpressLocalModels {
  GenuiExpressLocalModels._();

  /// Helper to extract the prompt (last user message) and system instruction
  /// from a [ModelRequest].
  static (String prompt, String? systemInstruction) _extractInputs(
    ModelRequest request,
  ) {
    final userMessage = request.messages.lastWhereOrNull(
      (m) => m.role == Role.user,
    );
    final prompt =
        userMessage?.content
            .where((p) => p.isText)
            .map((p) => p.text)
            .join('') ??
        '';

    final systemMessage = request.messages.firstWhereOrNull(
      (m) => m.role == Role.system,
    );
    final systemInstruction = systemMessage?.content
        .where((p) => p.isText)
        .map((p) => p.text)
        .join('');

    return (prompt, systemInstruction);
  }

  /// Registers Apple Intelligence (FoundationModels), Android AI Edge (Gemini Nano),
  /// and local developer HTTP models with the given [ai] instance.
  static void register(Genkit ai) {
    // 1. Apple Intelligence model
    ai.defineModel(
      name: 'local/apple-foundation-models',
      fn: (request, context) async {
        final (prompt, systemInstruction) = _extractInputs(request);

        final isAvailable =
            await _channel.invokeMethod<bool>('checkAvailability') ?? false;
        if (!isAvailable) {
          throw StateError(
            'FoundationModels framework is not available or configured on this device.',
          );
        }

        final Stream<String> nativeStream = _eventChannel
            .receiveBroadcastStream({
              'prompt': prompt,
              'systemPrompt': systemInstruction,
            })
            .cast<String>();

        final buffer = StringBuffer();
        await for (final chunk in nativeStream) {
          buffer.write(chunk);
          context.sendChunk(
            ModelResponseChunk(content: [TextPart(text: chunk)]),
          );
        }

        return ModelResponse(
          finishReason: FinishReason.stop,
          message: Message(
            role: Role.model,
            content: [TextPart(text: buffer.toString())],
          ),
        );
      },
    );

    // 2. Android AI Edge model
    ai.defineModel(
      name: 'local/android-ai-edge',
      fn: (request, context) async {
        final (prompt, systemInstruction) = _extractInputs(request);

        final isAvailable =
            await _channel.invokeMethod<bool>('checkAvailability') ?? false;
        if (!isAvailable) {
          throw StateError(
            'Google AI Edge SDK is not available or configured on this device.',
          );
        }

        final Stream<String> nativeStream = _eventChannel
            .receiveBroadcastStream({
              'prompt': prompt,
              'systemPrompt': systemInstruction,
            })
            .cast<String>();

        final buffer = StringBuffer();
        await for (final chunk in nativeStream) {
          buffer.write(chunk);
          context.sendChunk(
            ModelResponseChunk(content: [TextPart(text: chunk)]),
          );
        }

        return ModelResponse(
          finishReason: FinishReason.stop,
          message: Message(
            role: Role.model,
            content: [TextPart(text: buffer.toString())],
          ),
        );
      },
    );

    // 3. Local HTTP Completions model
    ai.defineModel(
      name: 'local/http-completion',
      fn: (request, context) async {
        final (prompt, systemInstruction) = _extractInputs(request);
        final client = HttpClient();
        final buffer = StringBuffer();
        try {
          // Default to local Ollama's OpenAI-compatible completions endpoint
          final Uri uri = Uri.parse(
            'http://localhost:11434/v1/chat/completions',
          );
          final HttpClientRequest httpReq = await client.postUrl(uri);
          httpReq.headers.contentType = ContentType.json;

          final payload = {
            'model': 'gemma',
            'messages': [
              if (systemInstruction != null)
                {'role': 'system', 'content': systemInstruction},
              {'role': 'user', 'content': prompt},
            ],
            'stream': true,
          };

          httpReq.write(jsonEncode(payload));
          final HttpClientResponse response = await httpReq.close();

          if (response.statusCode != 200) {
            throw HttpException(
              'Local HTTP completions server error: ${response.statusCode}',
            );
          }

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
                final firstChoice =
                    choices?.firstOrNull as Map<String, Object?>?;
                final delta = firstChoice?['delta'] as Map<String, Object?>?;
                final content = delta?['content'] as String?;
                if (content != null && content.isNotEmpty) {
                  buffer.write(content);
                  context.sendChunk(
                    ModelResponseChunk(content: [TextPart(text: content)]),
                  );
                }
              } catch (_) {
                // Ignore parse errors on comments or SSE headers
              }
            }
          }

          return ModelResponse(
            finishReason: FinishReason.stop,
            message: Message(
              role: Role.model,
              content: [TextPart(text: buffer.toString())],
            ),
          );
        } finally {
          client.close();
        }
      },
    );
  }
}
