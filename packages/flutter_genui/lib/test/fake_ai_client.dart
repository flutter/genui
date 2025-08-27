// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter/foundation.dart';

import '../src/ai_client/ai_client.dart';
import '../src/model/chat_message.dart' as genui;
import '../src/model/tools.dart';

/// A fake implementation of [AiClient] for testing purposes.
///
/// This class allows for mocking the behavior of an AI client by providing
/// canned responses or exceptions. It also tracks calls to its methods.
class FakeAiClient implements AiClient {
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

  /// A future to be returned by [generateContent].
  ///
  /// If this is non-null, [generateContent] will return this future.
  Future<dynamic>? generateContentFuture;

  @override
  Future<T?> generateContent<T extends Object>(
    List<genui.ChatMessage> conversation,
    Schema outputSchema, {
    Iterable<AiTool> additionalTools = const [],
  }) async {
    if (responseCompleter.isCompleted) {
      responseCompleter = Completer<void>();
    }
    generateContentCallCount++;
    lastConversation = conversation;
    try {
      if (preGenerateContent != null) {
        await preGenerateContent!();
      }
      if (exception != null) {
        throw exception!;
      }
      if (generateContentFuture != null) {
        return await generateContentFuture as T?;
      }
      return response as T?;
    } finally {
      if (!responseCompleter.isCompleted) {
        responseCompleter.complete();
      }
    }
  }

  @override
  Future<String> generateText(
    List<genui.ChatMessage> conversation, {
    Iterable<AiTool> additionalTools = const [],
  }) async {
    if (responseCompleter.isCompleted) {
      responseCompleter = Completer<void>();
    }
    generateTextCallCount++;
    lastConversation = conversation;
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
  ValueListenable<int> get activeRequests => _activeRequests;
  final ValueNotifier<int> _activeRequests = ValueNotifier<int>(0);

  @override
  void dispose() {
    _model.dispose();
    _activeRequests.dispose();
  }
}

/// A fake implementation of [AiModel] for testing purposes.
class FakeAiModel extends AiModel {
  /// Creates a new [FakeAiModel].
  FakeAiModel(this.displayName);

  @override
  final String displayName;
}
