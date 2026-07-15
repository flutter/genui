// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Exception thrown when client function execution fails.
class A2uiFunctionException implements Exception {
  /// Creates a [A2uiFunctionException].
  A2uiFunctionException(
    this.message, {
    required this.functionName,
    this.argumentKey,
    this.cause,
  });

  /// The sanitized diagnostic message.
  final String message;

  /// The name of the function that failed.
  final String functionName;

  /// The specific argument key that caused the error, if any.
  final String? argumentKey;

  /// The underlying cause of the error, if any.
  final Object? cause;

  @override
  String toString() {
    var result = 'A2uiFunctionException inside $functionName: $message';
    if (argumentKey != null) {
      result += ' (argument: $argumentKey)';
    }
    if (cause != null) {
      result += '\nCause: $cause';
    }
    return result;
  }
}
