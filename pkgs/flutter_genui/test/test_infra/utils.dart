// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';

import 'package:flutter_genui/src/ai_client/generative_model_interface.dart';

// A fake GenerativeModel that doesn't extend or implement the real one,
// to work around the final class restriction.
class FakeGenerativeModel implements GenerativeModelInterface {
  int generateContentCallCount = 0;
  GenerateContentResponse? response;
  List<GenerateContentResponse> responses = [];
  Exception? exception;

  @override
  Future<GenerateContentResponse> generateContent(
    Iterable<Content> content, {
    List<SafetySetting>? safetySettings,
    GenerationConfig? generationConfig,
    List<Tool>? tools,
    ToolConfig? toolConfig,
  }) async {
    generateContentCallCount++;
    if (exception != null) {
      final e = exception;
      exception = null; // Reset for next call
      throw e!;
    }
    if (responses.isNotEmpty) {
      return responses.removeAt(0);
    }
    if (response != null) {
      return response!;
    }
    throw StateError(
      'No response or exception configured for FakeGenerativeModel',
    );
  }
}

class BuildContextProvider extends StatelessWidget {
  final WidgetBuilder builder;
  late final BuildContext context;

  BuildContextProvider(this.builder, {super.key});

  @override
  Widget build(BuildContext context) {
    this.context = context;
    return builder(context);
  }
}
