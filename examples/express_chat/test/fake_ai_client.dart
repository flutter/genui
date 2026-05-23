// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:genkit/genkit.dart' as genkit;

/// A Genkit-based fake client implementation for integration tests.
class FakeGenkitClient {
  final genkit.Genkit ai = genkit.Genkit(isDevEnv: false);
  final List<String> responses = [];
  final List<String> receivedPrompts = [];

  FakeGenkitClient() {
    ai.defineModel(
      name: 'local/fake-model',
      fn: (request, context) async {
        // Extract the user prompt from request messages
        final genkit.Message? userMessage = request.messages.lastWhereOrNull(
          (m) => m.role == genkit.Role.user,
        );
        final String prompt =
            userMessage?.content
                .where((p) => p.isText)
                .map((p) => p.text)
                .join('') ??
            '';
        receivedPrompts.add(prompt);

        if (responses.isEmpty) {
          const resp = 'I have no response for that.';
          context.sendChunk(
            genkit.ModelResponseChunk(content: [genkit.TextPart(text: resp)]),
          );
          return genkit.ModelResponse(
            finishReason: genkit.FinishReason.stop,
            message: genkit.Message(
              role: genkit.Role.model,
              content: [genkit.TextPart(text: resp)],
            ),
          );
        }

        final String response = responses.removeAt(0);

        // Simulate streaming chunks
        const chunkSize = 10;
        for (var i = 0; i < response.length; i += chunkSize) {
          final int end = (i + chunkSize < response.length)
              ? i + chunkSize
              : response.length;
          final String chunk = response.substring(i, end);
          context.sendChunk(
            genkit.ModelResponseChunk(content: [genkit.TextPart(text: chunk)]),
          );
          await Future<void>.delayed(const Duration(milliseconds: 1));
        }

        return genkit.ModelResponse(
          finishReason: genkit.FinishReason.stop,
          message: genkit.Message(
            role: genkit.Role.model,
            content: [genkit.TextPart(text: response)],
          ),
        );
      },
    );
  }

  /// Adds a response to the queue.
  void addResponse(String response) {
    responses.add(response);
  }
}
