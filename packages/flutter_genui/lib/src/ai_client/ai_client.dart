// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter/foundation.dart';

import '../model/chat_message.dart';
import '../model/tools.dart';

/// An abstract class representing a type of AI model.
///
/// This class provides a common interface for different AI models.
abstract class AiModel {
  /// The display name of the model used to select the model in the UI.
  String get displayName;
}

/// An abstract class for a client that interacts with an AI model.
///
/// This class defines the interface for sending requests to an AI model and
/// receiving responses.
abstract interface class AiClient {
  /// A [ValueListenable] for the currently selected AI model.
  ///
  /// This allows the UI to listen for changes to the selected model.
  ValueListenable<AiModel> get model;

  /// The list of available AI models.
  List<AiModel> get models;

  /// Switches the AI model to the given [model].
  void switchModel(AiModel model);

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
