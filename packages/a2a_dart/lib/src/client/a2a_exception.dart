// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'a2a_exception.freezed.dart';
part 'a2a_exception.g.dart';

/// A sealed class for all A2A client-side exceptions.
@freezed
sealed class A2AException with _$A2AException implements Exception {
  /// An exception that represents a JSON-RPC error from the server.
  const factory A2AException.jsonRpc({
    /// The JSON-RPC error code.
    required int code,

    /// The JSON-RPC error message.
    required String message,

    /// Optional data associated with the error.
    Map<String, Object?>? data,
  }) = A2AJsonRpcException;

  /// An exception that represents an HTTP error.
  const factory A2AException.http({required int statusCode, String? reason}) =
      A2AHttpException;

  /// An exception that represents a network error.
  const factory A2AException.network({required String message}) =
      A2ANetworkException;

  /// An exception that represents a parsing error.
  const factory A2AException.parsing({
    /// The error message.
    required String message,
  }) = A2AParsingException;

  /// Creates an [A2AException] from a JSON object.
  factory A2AException.fromJson(Map<String, Object?> json) =>
      _$A2AExceptionFromJson(json);
}
