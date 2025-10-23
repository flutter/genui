// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'model/a2ui_message.dart';
import 'model/chat_message.dart';

/// An abstract interface for a content generator.
///
/// A content generator is responsible for generating UI content and handling
/// user interactions.
abstract interface class ContentGenerator {
  /// A stream of A2UI messages produced by the generator.
  ///
  /// The `UiAgent` will listen to this stream and forward messages
  /// to the `GenUiManager`.
  Stream<A2uiMessage> get a2uiMessageStream;

  /// A stream of text responses from the agent.
  Stream<String> get textResponseStream;

  /// Whether the content generator is currently processing a request.
  ValueListenable<bool> get isProcessing;

  /// Sends a user request to the content source.
  ///
  /// This can be a text message or a structured UI event.
  Future<void> sendRequest(UserMessage message);

  /// The full conversation history managed by the generator.
  ValueListenable<List<ChatMessage>> get conversation;

  /// Disposes of the resources used by this generator.
  void dispose();
}
