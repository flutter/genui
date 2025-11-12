// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../genui.dart';

/// A fake [ContentGenerator] for use in tests.
class FakeContentGenerator implements ContentGenerator {
  FakeContentGenerator();

  final _a2uiMessageController = StreamController<A2uiMessage>.broadcast();
  final _textResponseController = StreamController<String>.broadcast();
  final _errorController = StreamController<ContentGeneratorError>.broadcast();
  final _isProcessing = ValueNotifier<bool>(false);

  /// A completer that can be used to pause [sendRequest].
  ///
  /// Tests can await this completer to control the execution of `sendRequest`.
  Completer<void>? sendRequestCompleter;

  /// The number of times [sendRequest] has been called.
  int sendRequestCallCount = 0;

  /// The last message passed to [sendRequest].
  ChatMessage? lastMessage;

  /// The last history passed to [sendRequest].
  Iterable<ChatMessage>? lastHistory;

  @override
  Stream<A2uiMessage> get a2uiMessageStream => _a2uiMessageController.stream;

  @override
  Stream<String> get textResponseStream => _textResponseController.stream;

  @override
  Stream<ContentGeneratorError> get errorStream => _errorController.stream;

  @override
  ValueListenable<bool> get isProcessing => _isProcessing;

  @override
  void dispose() {
    _a2uiMessageController.close();
    _textResponseController.close();
    _errorController.close();
    _isProcessing.dispose();
  }

  @override
  Future<void> sendRequest(
    ChatMessage message, {
    Iterable<ChatMessage>? history,
  }) async {
    _isProcessing.value = true;
    try {
      sendRequestCallCount++;
      lastMessage = message;
      lastHistory = history;
      if (sendRequestCompleter != null) {
        await sendRequestCompleter!.future;
      }
    } finally {
      _isProcessing.value = false;
    }
  }

  /// Adds an A2UI message to the stream.
  void addA2uiMessage(A2uiMessage message) {
    _a2uiMessageController.add(message);
  }

  /// Adds a text response to the stream.
  void addTextResponse(String response) {
    _textResponseController.add(response);
  }
}
