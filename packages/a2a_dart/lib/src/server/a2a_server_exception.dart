// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'a2a_server.dart';
library;

/// An exception thrown by the [A2AServer].
class A2AServerException implements Exception {
  /// The error message.
  final String message;

  /// The JSON-RPC 2.0 error code.
  final int code;

  /// Creates an [A2AServerException].
  A2AServerException(this.message, this.code);
}
