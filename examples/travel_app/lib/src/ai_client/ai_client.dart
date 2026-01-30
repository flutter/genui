// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:genui/genui.dart';

/// An abstract interface for AI clients.
///
/// This interface defines the contract for communicating with an AI service,
/// regardless of the implementation (e.g., Google Generative AI, fake client).
abstract interface class AiClient {
  /// The stream of [A2uiMessage]s received from the AI.
  Stream<A2uiMessage> get a2uiMessageStream;

  /// The stream of text chunks received from the AI.
  Stream<String> get textResponseStream;

  /// Sends a message to the AI service.
  ///
  /// [message] is the new message to send.
  /// [history] is the history of the conversation so far.
  Future<void> sendRequest(
    ChatMessage message, {
    Iterable<ChatMessage>? history,
  });

  /// Dispose of resources.
  void dispose();
}
