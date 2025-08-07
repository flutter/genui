// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

// TODO(gspencer): Remove this dependency on firebase_ai.  It currently supplies
// Content, Part and Schema, which will need to be refactored as generic
// versions.
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_genui/src/ai_client/tools.dart';

class FakeAiClient implements AiClient {
  Object? response;
  Exception? exception;
  int generateContentCallCount = 0;
  List<Content> lastConversation = [];
  Future<void> Function()? preGenerateContent;

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
    return response as T?;
  }

  @override
  ValueListenable<AiModel> get model => ValueNotifier<AiModel>(_FakeAiModel());

  @override
  List<AiModel> get models => [_FakeAiModel()];

  @override
  void switchModel(AiModel model) {}
}

class _FakeAiModel extends AiModel {
  @override
  String get displayName => 'fake';
}
