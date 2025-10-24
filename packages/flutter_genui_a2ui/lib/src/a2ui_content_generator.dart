// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_genui/flutter_genui.dart';

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
  final _conversation = ValueNotifier<List<ChatMessage>>([]);
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

  ValueListenable<List<ChatMessage>> get conversation => _conversation;

  @override
  void dispose() {
    _conversation.dispose();
    _textResponseController.close();
    connector.dispose();
    _isProcessing.dispose();
  }

  @override
  Future<void> sendRequest(Iterable<ChatMessage> messages) async {
    _isProcessing.value = true;
    try {
      _conversation.value = messages.toList();
      final lastUserMessage = messages.whereType<UserMessage>().lastOrNull;

      if (lastUserMessage == null) {
        _errorResponseController.add(ContentGeneratorError(
          'No UserMessage found to send',
          StackTrace.current,
        ));
        return;
      }

      final responseText = await connector.connectAndSend(lastUserMessage);
      if (responseText != null && responseText.isNotEmpty) {
        _textResponseController.add(responseText);
        _addMessage(AiTextMessage([TextPart(responseText)]));
      }
    } finally {
      _isProcessing.value = false;
    }
  }

  void _addMessage(ChatMessage message) {
    _conversation.value = [..._conversation.value, message];
  }
}
