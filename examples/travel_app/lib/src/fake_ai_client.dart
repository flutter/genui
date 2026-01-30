// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:genui/genui.dart';

import 'ai_client/ai_client.dart';

class FakeAiClient implements AiClient {
  final _a2uiMessageController = StreamController<A2uiMessage>.broadcast();
  final _textResponseController = StreamController<String>.broadcast();
  final _errorController = StreamController<Object>.broadcast();

  @override
  Stream<A2uiMessage> get a2uiMessageStream => _a2uiMessageController.stream;
  @override
  Stream<String> get textResponseStream => _textResponseController.stream;
  Stream<Object> get errorStream => _errorController.stream;

  int sendRequestCallCount = 0;
  Completer<void>? sendRequestCompleter;

  @override
  Future<void> sendRequest(
    ChatMessage message, {
    Iterable<ChatMessage>? history,
  }) async {
    sendRequestCallCount++;
    if (sendRequestCompleter != null) {
      await sendRequestCompleter!.future;
    }
  }

  void addA2uiMessage(A2uiMessage message) {
    _a2uiMessageController.add(message);
  }

  void addTextResponse(String text) {
    _textResponseController.add(text);
  }

  void addError(Object error) {
    _errorController.add(error);
  }

  @override
  void dispose() {
    _a2uiMessageController.close();
    _textResponseController.close();
    _errorController.close();
  }
}
