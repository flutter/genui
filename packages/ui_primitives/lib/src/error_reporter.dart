// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class FrameworkErrorReporter {
  /// Set this instance to customize error reporting for the framework.
  static FrameworkErrorReporter instance = FrameworkErrorReporter();

  /// Creates a the framework specific error with the given message.
  Error createError(String message, {FrameworkErrorDetails? details}) =>
      _FrameworkError(message: message, details: details);

  /// Reports [FrameworkErrorDetails] according to the framework settings.
  ///
  /// Depending on settings, it may throw an exception, log an error,
  /// or debug-stop the execution.
  void report(FrameworkErrorDetails details) =>
      throw _FrameworkError(details: details);
}

final class _FrameworkError extends Error {
  _FrameworkError({this.message, this.details});

  final FrameworkErrorDetails? details;
  final String? message;

  @override
  String toString() {
    return [message, details].where((e) => e != null).join('\n');
  }
}

final class FrameworkErrorDetails {
  FrameworkErrorDetails({
    required this.exception,
    this.dispatchingObject,
    this.stack,
  });

  final Object? dispatchingObject;
  final Object exception;
  final StackTrace? stack;

  @override
  String toString() {
    return '$dispatchingObject reported $exception\n$stack';
  }
}
