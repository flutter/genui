// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../src/ai_client/ai_client.dart';
import '../src/model/chat_message.dart' as genui;
import '../src/model/tools.dart';

/// A fake implementation of [AiClient] for testing purposes.
///
/// This class allows for mocking the behavior of an AI client by providing
/// canned responses or exceptions. It also tracks calls to its methods.
class FakeAiClient implements AiClient {
  /// The response to be returned by [generateText].
  String? response;

  /// The number of times [generateText] has been called.
  int generateTextCallCount = 0;

  /// The last conversation passed to [generateText].
  List<genui.ChatMessage> lastConversation = [];

  /// A function to be called before [generateText] returns.
  Future<void> Function()? preGenerateText;

  /// An exception to be thrown by [generateText].
  Exception? exception;

  /// A completer that completes when [generateText] is finished.
  ///
  /// This can be used to wait for the response to be processed.
  Completer<void> responseCompleter = Completer<void>();

  /// A future to be returned by [generateText].
  ///
  /// If this is non-null, [generateText] will return this future.
  Future<String>? generateTextFuture;

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
      if (preGenerateText != null) {
        await preGenerateText!();
      }
      if (exception != null) {
        throw exception!;
      }
      if (generateTextFuture != null) {
        return await generateTextFuture!;
      }
      return response ?? '';
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
