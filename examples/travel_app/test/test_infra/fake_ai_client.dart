// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:firebase_ai/firebase_ai.dart' show Content;
import 'package:flutter/foundation.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_genui/src/ai_client/tools.dart';

class FakeAiClient implements AiClient {
  Object? response;
  Exception? exception;
  int generateContentCallCount = 0;
  List<Content> lastConversation = [];
  Future<void> Function()? preGenerateContent;
  final Completer<void> _responseCompleter = Completer<void>();

  @override
  Future<T?> generateContent<T extends Object>(
    List<Content> conversation,
    Schema outputSchema, {
    Iterable<AiTool> additionalTools = const [],
  }) async {
    await preGenerateContent?.call();
    generateContentCallCount++;
    lastConversation = List.from(conversation);
    if (exception != null) {
      final e = exception;
      exception = null; // Reset for next call
      throw e!;
    }
    // Allow tests to wait for this to be called.
    _responseCompleter.complete();
    return response as T?;
  }

  Future<void> get responseFinished => _responseCompleter.future;

  final _model = ValueNotifier<AiModel>(_MockAiModel('mock1'));

  @override
  ValueListenable<AiModel> get model => _model;

  @override
  List<AiModel> get models => [_MockAiModel('mock1'), _MockAiModel('mock2')];

  @override
  void switchModel(AiModel model) {
    _model.value = model;
  }
}

class _MockAiModel extends AiModel {
  _MockAiModel(this.displayName);

  @override
  final String displayName;
}
