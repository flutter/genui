// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter/foundation.dart';

import '../model/chat_message.dart';
import '../model/tools.dart';

/// An abstract class for a client that interacts with an AI model.
///
/// This class defines the interface for sending requests to an AI model and
/// receiving responses.
abstract interface class AiClient {
  /// Generates content from the given [conversation] and returns an object of
  /// type [T] that conforms to the given [outputSchema].
  ///
  /// The [additionalTools] are added to the list of tools available to the
  /// AI model.
  Future<T?> generateContent<T extends Object>(
    List<ChatMessage> conversation,
    Schema outputSchema, {
    Iterable<AiTool> additionalTools = const [],
  });

  /// Generates a text response from the given [conversation].
  ///
  /// The [additionalTools] are added to the list of tools available to the
  /// AI model, but the model is not required to use them.
  Future<String> generateText(
    List<ChatMessage> conversation, {
    Iterable<AiTool> additionalTools = const [],
  });

  /// Number of requests being processed.
  ValueListenable<int> get activeRequests;

  /// Disposes of the resources used by this client.
  void dispose();
}

/// An exception thrown by an [AiClient] or its subclasses.
class AiClientException implements Exception {
  /// Creates an [AiClientException] with the given [message].
  AiClientException(this.message);

  /// The message associated with the exception.
  final String message;

  @override
  String toString() => '$AiClientException: $message';
}
