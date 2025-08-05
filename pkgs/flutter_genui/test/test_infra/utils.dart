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
  PromptFeedback? promptFeedback;

  @override
  Future<GenerateContentResponse> generateContent(
    Iterable<Content> content,
  ) async {
    generateContentCallCount++;
    if (exception != null) {
      final e = exception;
      exception = null; // Reset for next call
      throw e!;
    }
    if (responses.isNotEmpty) {
      final response = responses.removeAt(0);
      return GenerateContentResponse(response.candidates, promptFeedback);
    }
    if (response != null) {
      return GenerateContentResponse(response!.candidates, promptFeedback);
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
