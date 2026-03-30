// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class FrameworkErrorReporter {
  /// Set this instance to customize error reporting for the framework.
  static FrameworkErrorReporter instance = FrameworkErrorReporter();

  Error error(String message) => FrameworkError(message: message);

  /// Reports [FrameworkErrorDetails] according to the framework settings.
  ///
  /// Depending on settings, it may throw an exception, log an error,
  /// or debug-stop the execution.
  void report(FrameworkErrorDetails details) =>
      throw FrameworkError(details: details);
}

final class FrameworkError extends Error {
  FrameworkError({this.message, this.details});

  final FrameworkErrorDetails? details;
  final String? message;
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
}
