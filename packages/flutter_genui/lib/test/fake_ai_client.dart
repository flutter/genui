// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter/foundation.dart';

import '../flutter_genui.dart';

/// A fake [AiClient] for use in tests.
class FakeAiClient implements AiClient {
  /// The response to return from [generateContent].
  late Object response;

  /// A future to return from [generateContent].
  Future<Object?>? generateContentFuture;

  /// The number of times [generateContent] has been called.
  int generateContentCallCount = 0;

  /// The last conversation passed to [generateContent].
  List<ChatMessage> lastConversation = [];

  /// A completer that completes when a response is returned from
  /// [generateContent].
  Completer<void> responseCompleter = Completer<void>();

  @override
  Future<T?> generateContent<T extends Object>(
    Iterable<ChatMessage> conversation,
    Schema outputSchema, {
    Iterable<AiTool> additionalTools = const [],
  }) async {
    generateContentCallCount++;
    lastConversation = conversation.toList();
    if (generateContentFuture != null) {
      final result = await generateContentFuture;
      responseCompleter.complete();
      return result as T?;
    }
    responseCompleter.complete();
    return response as T?;
  }

  @override
  Future<String> generateText(
    Iterable<ChatMessage> conversation, {
    Iterable<AiTool> additionalTools = const [],
  }) async {
    return '';
  }

  @override
  ValueListenable<int> get activeRequests => _activeRequests;
  final ValueNotifier<int> _activeRequests = ValueNotifier(0);

  @override
  void dispose() {
    _activeRequests.dispose();
  }
}
