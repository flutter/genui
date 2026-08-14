// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:a2ui_core/a2ui_core.dart' as core;
import 'package:genui/genui.dart';

import 'agent/agent.dart';
import 'agent/ai_client.dart';

/// A [Transport] that communicates with [SimpleChatAgent].
class SimpleChatA2aTransport implements Transport {
  SimpleChatA2aTransport({AiClient? aiClient}) {
    _agent = SimpleChatAgent(
      aiClient: aiClient,
      onChunkFromAgent: _adapter.addChunk,
    );
  }

  late final SimpleChatAgent _agent;
  final A2uiTransportAdapter _adapter = A2uiTransportAdapter();

  @override
  Stream<core.A2uiMessage> get incomingMessages => _adapter.incomingMessages;

  @override
  Stream<String> get incomingText => _adapter.incomingText;

  @override
  Future<void> sendRequest(ChatMessage message) async {
    await _agent.handleRequestFromRenderer(message);
  }

  @override
  void dispose() => _adapter.dispose();

  /// Adds a system message to the history.
  void addSystemMessage(String content) => _agent.addSystemMessage(content);
}
