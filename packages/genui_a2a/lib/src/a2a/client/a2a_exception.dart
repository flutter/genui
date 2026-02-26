// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'a2a_exception.freezed.dart';
part 'a2a_exception.g.dart';

/// Base class for exceptions thrown by the A2A client.
///
/// This sealed class hierarchy represents different categories of errors
/// that can occur during communication with an A2A server.
@freezed
sealed class A2AException with _$A2AException implements Exception {
  /// Represents a JSON-RPC error returned by the server.
  ///
  /// This exception is thrown when the server responds with a JSON-RPC error
  /// object, indicating a problem with the request as understood by the A2A
  /// protocol.
  const factory A2AException.jsonRpc({
    /// The integer error code as defined by the JSON-RPC 2.0 specification
    /// or A2A-specific error codes.
    required int code,

    /// A human-readable string describing the error.
    required String message,

    /// Optional additional data provided by the server about the error.
    Map<String, Object?>? data,
  }) = A2AJsonRpcException;

  const factory A2AException.taskNotFound({
    required String message,
    Map<String, Object?>? data,
  }) = A2ATaskNotFoundException;

  const factory A2AException.taskNotCancelable({
    required String message,
    Map<String, Object?>? data,
  }) = A2ATaskNotCancelableException;

  const factory A2AException.pushNotificationNotSupported({
    required String message,
    Map<String, Object?>? data,
  }) = A2APushNotificationNotSupportedException;

  const factory A2AException.pushNotificationConfigNotFound({
    required String message,
    Map<String, Object?>? data,
  }) = A2APushNotificationConfigNotFoundException;

  /// Represents an error related to the HTTP transport layer.
  ///
  /// This exception is thrown when an HTTP request fails with a non-2xx status
  /// code, and the issue is not a specific JSON-RPC error.
  const factory A2AException.http({
    /// The HTTP status code (e.g., 404, 500).
    required int statusCode,

    /// An optional human-readable reason phrase associated with the status
    /// code.
    String? reason,
  }) = A2AHttpException;

  /// Represents a network connectivity issue.
  ///
  /// This exception is thrown when a connection to the server cannot be
  /// established or is interrupted.
  const factory A2AException.network({
    /// A message describing the network error.
    required String message,
  }) = A2ANetworkException;

  /// Represents an error during the parsing of a server response.
  ///
  /// This exception is thrown if the client fails to parse the server's
  /// response, for example, due to malformed JSON.
  const factory A2AException.parsing({
    /// A message describing the parsing failure.
    required String message,
  }) = A2AParsingException;

  /// Represents an operation that is not supported by the current
  /// implementation.
  const factory A2AException.unsupportedOperation({required String message}) =
      A2AUnsupportedOperationException;

  /// Deserializes an [A2AException] from a JSON object.
  factory A2AException.fromJson(Map<String, Object?> json) =>
      _$A2AExceptionFromJson(json);
}
