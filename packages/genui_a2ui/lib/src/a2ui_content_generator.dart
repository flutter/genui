// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';

import 'a2ui_agent_connector.dart';

/// A content generator that connects to an A2UI server.
class A2uiContentGenerator implements ContentGenerator {
  /// Creates an [A2uiContentGenerator] instance.
  ///
  /// If optional `connector` is not supplied, then one will be created with the
  /// given `serverUrl`.
  A2uiContentGenerator({required Uri serverUrl, A2uiAgentConnector? connector})
    : connector = connector ?? A2uiAgentConnector(url: serverUrl) {
    this.connector.errorStream.listen((Object error) {
      _errorResponseController.add(
        ContentGeneratorError(error, StackTrace.current),
      );
    });
  }

  final A2uiAgentConnector connector;
  final _textResponseController = StreamController<String>.broadcast();
  final _errorResponseController =
      StreamController<ContentGeneratorError>.broadcast();
  final _isProcessing = ValueNotifier<bool>(false);

  @override
  Stream<A2uiMessage> get a2uiMessageStream => connector.stream;

  @override
  Stream<String> get textResponseStream => _textResponseController.stream;

  @override
  Stream<ContentGeneratorError> get errorStream =>
      _errorResponseController.stream;

  @override
  ValueListenable<bool> get isProcessing => _isProcessing;

  @override
  void dispose() {
    _textResponseController.close();
    connector.dispose();
    _isProcessing.dispose();
  }

  @override
  Future<void> sendRequest(
    ChatMessage message, {
    Iterable<ChatMessage>? history,
    A2UiClientCapabilities? clientCapabilities,
  }) async {
    _isProcessing.value = true;
    try {
      if (history != null && history.isNotEmpty) {
        genUiLogger.warning(
          'A2uiContentGenerator is stateful and ignores history.',
        );
      }
      final String? responseText = await connector.connectAndSend(
        message,
        clientCapabilities: clientCapabilities,
      );
      if (responseText != null && responseText.isNotEmpty) {
        _textResponseController.add(responseText);
      }
    } finally {
      _isProcessing.value = false;
    }
  }
}
