// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class ListenableErrorReporting {
  /// Creates an error with the given message.
  static Error createError(String message, {ListenableErrorDetails? details}) =>
      ListenableError(message: message, details: details);

  /// Reports an error.
  ///
  /// Depending on settings, it may throw an exception, log an error,
  /// or debug-stop the execution.
  ///
  /// In current implementation it just throws an error,
  /// but it may be reconsidered in future.
  static void report(ListenableErrorDetails details) =>
      throw ListenableError(details: details);
}

final class ListenableError extends Error {
  ListenableError({this.message, this.details});

  final ListenableErrorDetails? details;
  final String? message;

  @override
  String toString() {
    return [message, details].where((e) => e != null).join('\n');
  }
}

final class ListenableErrorDetails {
  ListenableErrorDetails({
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
