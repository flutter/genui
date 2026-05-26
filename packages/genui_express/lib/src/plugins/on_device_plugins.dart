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

  /// Apple Intelligence local foundation models reference.
  static const String appleFoundationModels = 'local/apple-foundation-models';

  /// Google Android AI Edge (Gemini Nano) reference.
  static const String androidAiEdge = 'local/android-ai-edge';

  /// Developer local HTTP completions model reference.
  static const String httpCompletion = 'local/http-completion';

  /// Helper to extract the prompt (last user message) and system instruction
  /// from a [ModelRequest].
  static (String prompt, String? systemInstruction) _extractInputs(
    ModelRequest request,
  ) {
    final Message? userMessage = request.messages.lastWhereOrNull(
      (m) => m.role == Role.user,
    );
    final String prompt =
        userMessage?.content
            .where((p) => p.isText)
            .map((p) => p.text)
            .join('') ??
        '';

    final Message? systemMessage = request.messages.firstWhereOrNull(
      (m) => m.role == Role.system,
    );
    final String? systemInstruction = systemMessage?.content
        .where((p) => p.isText)
        .map((p) => p.text)
        .join('');

    return (prompt, systemInstruction);
  }

  /// Registers Apple Intelligence (FoundationModels), Android AI Edge (Gemini
  /// Nano), and local developer HTTP models with the given [ai] instance.
  static void register(Genkit ai) {
    // 1. Apple Intelligence model
    ai.defineModel(
      name: appleFoundationModels,
      fn: (request, context) async {
        final (String prompt, String? systemInstruction) = _extractInputs(
          request,
        );

        final bool isAvailable =
            await _channel.invokeMethod<bool>('checkAvailability') ?? false;
        if (!isAvailable) {
          throw StateError(
            'FoundationModels framework is not available or configured on '
            'this device.',
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
      name: androidAiEdge,
      fn: (request, context) async {
        final (String prompt, String? systemInstruction) = _extractInputs(
          request,
        );

        final bool isAvailable =
            await _channel.invokeMethod<bool>('checkAvailability') ?? false;
        if (!isAvailable) {
          throw StateError(
            'Google AI Edge SDK is not available or configured on this '
            'device.',
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
      name: httpCompletion,
      fn: (request, context) async {
        final (String prompt, String? systemInstruction) = _extractInputs(
          request,
        );
        final client = HttpClient();
        final buffer = StringBuffer();
        try {
          // Support dynamic configurations via request options,
          // defaulting to the local MLX server on port 8080.
          final String baseUrl =
              request.config?['baseUrl'] as String? ??
              'http://localhost:8080/v1';
          final String modelName =
              request.config?['model'] as String? ??
              'mlx-community/gemma-4-e2b-it-4bit';

          final Uri uri = Uri.parse('$baseUrl/chat/completions');
          final HttpClientRequest httpReq = await client.postUrl(uri);
          httpReq.headers.contentType = ContentType.json;

          final Map<String, Object> payload = {
            'model': modelName,
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
