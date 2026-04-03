// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class ListenableErrorReporting {
  /// Creates an error with the given message.
  static Error createError(String message) =>
      ListenableError(ListenableErrorDetails(exception: message));

  /// Reports an error.
  ///
  /// Adds the error to [reportedErrors].
  static void report(ListenableErrorDetails details) =>
      _reportedErrors.add(details);

  /// Returns the list of reported errors.
  static Iterable<ListenableErrorDetails> get reportedErrors => _reportedErrors;
  static final _reportedErrors = <ListenableErrorDetails>[];

  /// Clears the list of reported errors.
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
    final parts = [
      if (dispatchingObject != null) '$dispatchingObject reported $exception'
      else '$exception',
      if (stack != null) '$stack',
    ];
    return parts.join('\n');
  }
}
