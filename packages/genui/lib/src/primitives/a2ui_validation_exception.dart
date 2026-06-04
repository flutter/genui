// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Exception thrown when an A2UI message fails parsing or validation.
class A2uiValidationException implements Exception {
  /// Creates an [A2uiValidationException].
  A2uiValidationException(
    this.message, {
    this.surfaceId,
    this.path,
    this.json,
    this.cause,
  });

  final String message;
  final String? surfaceId;
  final String? path;
  final Object? json;
  final Object? cause;

  @override
  String toString() {
    final buffer = StringBuffer('A2uiValidationException: $message');
    if (surfaceId != null) buffer.write(' (surface: $surfaceId)');
    if (path != null) buffer.write(' (path: $path)');
    if (cause != null) buffer.write('\nCause: $cause');
    if (json != null) buffer.write('\nJSON: $json');
    return buffer.toString();
  }
}
