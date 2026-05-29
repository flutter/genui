// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:genkit/genkit.dart';
import 'package:genui_express_platform_interface/genui_express_platform_interface.dart';

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
    // 1. Apple Intelligence model (Delegates to Platform Interface on Web)
    ai.defineModel(
      name: appleFoundationModels,
      fn: (request, context) async {
        final (String prompt, String? systemInstruction) = _extractInputs(
          request,
        );

        final bool isAvailable = await GenuiExpressPlatform.instance
            .checkAvailability();
        if (!isAvailable) {
          throw StateError(
            'Local built-in AI models are not available or '
            'configured in this browser.',
          );
        }

        final Stream<String> nativeStream = GenuiExpressPlatform.instance
            .generateStream(prompt, systemInstruction);

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

    // 2. Android AI Edge model (Delegates to Platform Interface on Web)
    ai.defineModel(
      name: androidAiEdge,
      fn: (request, context) async {
        final (String prompt, String? systemInstruction) = _extractInputs(
          request,
        );

        final bool isAvailable = await GenuiExpressPlatform.instance
            .checkAvailability();
        if (!isAvailable) {
          throw StateError(
            'Local built-in AI models are not available or '
            'configured in this browser.',
          );
        }

        final Stream<String> nativeStream = GenuiExpressPlatform.instance
            .generateStream(prompt, systemInstruction);

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

    // 3. Local HTTP Completions model (Unsupported on Web)
    ai.defineModel(
      name: httpCompletion,
      fn: (request, context) async {
        throw UnsupportedError(
          'Local HTTP Completions model is not supported on the Web platform.',
        );
      },
    );
  }
}
