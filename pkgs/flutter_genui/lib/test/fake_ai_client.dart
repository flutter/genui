// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_genui/src/ai_client/gemini_ai_client.dart';
import 'package:dart_schema_builder/dart_schema_builder.dart' as dsb;

import '../src/model/chat_message.dart' as genui;
import '../src/model/tools.dart';

/// A fake implementation of [GeminiAiClient] for testing purposes.
///
/// This class allows for mocking the behavior of an AI client by providing
/// canned responses or exceptions. It also tracks calls to its methods.
class FakeAiClient implements GeminiAiClient {
  /// The response to be returned by [generateContent].
  Object? response;

  /// The response to be returned by [generateText].
  String? textResponse;

  /// The number of times [generateContent] has been called.
  int generateContentCallCount = 0;

  /// The number of times [generateText] has been called.
  int generateTextCallCount = 0;

  /// The last conversation passed to [generateContent].
  List<genui.ChatMessage> lastConversation = [];

  /// A function to be called before [generateContent] returns.
  Future<void> Function()? preGenerateContent;

  /// An exception to be thrown by [generateContent] or [generateText].
  Exception? exception;

  /// A completer that completes when [generateContent] is finished.
  ///
  /// This can be used to wait for the response to be processed.
  Completer<void> responseCompleter = Completer<void>();

  @override
  Future<T?> generateContent<T extends Object>(
    dsb.Schema outputSchema, {
    List<genui.ChatMessage>? conversation,
    List<Content>? content,
    Iterable<AiTool> additionalTools = const [],
  }) async {
    if (responseCompleter.isCompleted) {
      responseCompleter = Completer<void>();
    }
    generateContentCallCount++;
    lastConversation = conversation ?? [];
    try {
      if (preGenerateContent != null) {
        await preGenerateContent!();
      }
      if (exception != null) {
        throw exception!;
      }
      return response as T?;
    } finally {
      if (!responseCompleter.isCompleted) {
        responseCompleter.complete();
      }
    }
  }

  @override
  Future<String> generateText({
    List<genui.ChatMessage>? conversation,
    List<Content>? content,
    Iterable<AiTool> additionalTools = const [],
  }) async {
    if (responseCompleter.isCompleted) {
      responseCompleter = Completer<void>();
    }
    generateTextCallCount++;
    lastConversation = conversation ?? [];
    try {
      if (preGenerateContent != null) {
        await preGenerateContent!();
      }
      if (exception != null) {
        throw exception!;
      }
      return textResponse ?? '';
    } finally {
      if (!responseCompleter.isCompleted) {
        responseCompleter.complete();
      }
    }
  }

  @override
  ValueListenable<AiModel> get model => _model;
  final ValueNotifier<AiModel> _model = ValueNotifier<AiModel>(
    FakeAiModel('mock1'),
  );

  @override
  List<AiModel> get models => [FakeAiModel('mock1'), FakeAiModel('mock2')];

  @override
  void switchModel(AiModel model) {
    _model.value = model;
  }

  @override
  int inputTokenUsage = 0;

  @override
  int maxConcurrentJobs = 20;

  @override
  GenerativeModelFactory modelCreator =
      GeminiAiClient.defaultGenerativeModelFactory;

  @override
  int outputTokenUsage = 0;

  @override
  String outputToolName = 'provideFinalOutput';

  @override
  String? systemInstruction;

  @override
  List<AiTool> tools = [];
}

/// A fake implementation of [AiModel] for testing purposes.
class FakeAiModel extends AiModel {
  /// Creates a new [FakeAiModel].
  FakeAiModel(this.displayName);

  @override
  final String displayName;
}
