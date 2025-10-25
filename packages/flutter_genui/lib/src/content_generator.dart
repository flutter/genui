// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'model/a2ui_message.dart';
import 'model/chat_message.dart';

/// An error produced by a [ContentGenerator].
final class ContentGeneratorError {
  /// The error that occurred.
  final Object error;

  /// The stack trace of the error.
  final StackTrace stackTrace;

  /// Creates a [ContentGeneratorError].
  const ContentGeneratorError(this.error, this.stackTrace);
}

/// An abstract interface for a content generator.
///
/// A content generator is responsible for generating UI content and handling
/// user interactions.
abstract interface class ContentGenerator {
  /// A stream of A2UI messages produced by the generator.
  ///
  /// The `GenUiConversation` will listen to this stream and forward messages
  /// to the `GenUiManager`.
  Stream<A2uiMessage> get a2uiMessageStream;

  /// A stream of text responses from the agent.
  Stream<String> get textResponseStream;

  /// A stream of errors from the agent.
  Stream<ContentGeneratorError> get errorStream;

  /// Whether the content generator is currently processing a request.
  ValueListenable<bool> get isProcessing;

  /// Sends a message to the content source to generate a response, optionally
  /// including the previous conversation history.
  ///
  /// Some implementations, particularly those that manage their own state
  /// (stateful), may ignore the `history` parameter.
  Future<void> sendRequest(
    ChatMessage message, {
    Iterable<ChatMessage>? history,
  });

  /// Disposes of the resources used by this generator.
  void dispose();
}
