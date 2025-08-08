// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter/foundation.dart';

import '../model/chat_message.dart';
import 'tools.dart';

/// An abstract class representing a type of AI model.
abstract class AiModel {
  /// The display name of the model used to select the model in the UI.
  String get displayName;
}

/// An abstract class for a client that interacts with an AI model.
abstract interface class AiClient {
  /// A [ValueListenable] for the currently selected AI model.
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
}

/// The severity of a log message from the AI client.
enum AiLoggingSeverity {
  /// A trace message, for detailed debugging.
  trace,

  /// A debug message, for debugging.
  debug,

  /// An informational message.
  info,

  /// A warning message.
  warning,

  /// An error message.
  error,

  /// A fatal error message.
  fatal,
}

/// A callback for logging messages from the AI client.
typedef AiClientLoggingCallback =
    void Function(AiLoggingSeverity severity, String message);

/// An exception thrown by an [AiClient] or its subclasses.
class AiClientException implements Exception {
  /// Creates an [AiClientException] with the given [message].
  AiClientException(this.message);

  /// The message associated with the exception.
  final String message;

  @override
  String toString() => '$AiClientException: $message';
}
