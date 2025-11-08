// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'a2a_server.dart';
library;

/// Represents an error that occurred within the [A2AServer].
///
/// This exception is used to signal issues specific to the server-side
/// handling of A2A requests, often mapping to JSON-RPC error responses.
class A2AServerException implements Exception {
  /// A human-readable description of the error.
  final String message;

  /// The JSON-RPC 2.0 error code to be returned to the client.
  ///
  /// Standard codes are defined in the JSON-RPC specification, but custom codes
  /// can also be used.
  final int code;

  /// Creates an [A2AServerException].
  ///
  /// The [message] provides details about the error, and the [code]
  /// is a JSON-RPC error code.
  A2AServerException(this.message, this.code);

  @override
  String toString() => 'A2AServerException(code: $code, message: $message)';
}
