// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class ListenableErrorReporting {
  /// Creates an error with the given message.
  static Error createError(String message) =>
      ListenableError(ListenableErrorDetails(exception: message));

  /// Reports an error.
  ///
  /// Depending on settings, it may throw an exception, log an error,
  /// or debug-stop the execution.
  ///
  /// In current implementation it just throws an error,
  /// but it may be reconsidered in future.
  static void report(ListenableErrorDetails details) =>
      _reportedErrors.add(details);

  static Iterable<ListenableErrorDetails> get reportedErrors => _reportedErrors;
  static final _reportedErrors = <ListenableErrorDetails>[];

  static void clearReportedErrors() => _reportedErrors.clear();
}

final class ListenableError extends Error {
  ListenableError(this.details);

  final ListenableErrorDetails details;

  @override
  String toString() {
    return details.toString();
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
