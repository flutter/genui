// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter/foundation.dart';

import '../flutter_genui.dart';
import '../src/ai_client/tools.dart';
import '../src/model/chat_message.dart' as genui;

/// A fake implementation of [AiClient] for testing purposes.
///
/// This class allows for mocking the behavior of an AI client by providing
/// canned responses or exceptions. It also tracks calls to its methods.
class FakeAiClient implements AiClient {
  /// The response to be returned by [generateContent].
  Object? response;

  /// The number of times [generateContent] has been called.
  int generateContentCallCount = 0;

  /// The last conversation passed to [generateContent].
  List<genui.ChatMessage> lastConversation = [];

  /// A function to be called before [generateContent] returns.
  Future<void> Function()? preGenerateContent;

  /// An exception to be thrown by [generateContent].
  Exception? exception;

  /// A completer that completes when [generateContent] is finished.
  ///
  /// This can be used to wait for the response to be processed.
  Completer<void> responseCompleter = Completer<void>();

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
      return response as T?;
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
}

/// A fake implementation of [AiModel] for testing purposes.
class FakeAiModel extends AiModel {
  /// Creates a new [FakeAiModel].
  FakeAiModel(this.displayName);

  @override
  final String displayName;
}
