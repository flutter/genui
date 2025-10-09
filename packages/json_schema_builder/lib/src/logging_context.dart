// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A context for logging validation steps.
///
/// This is used for debugging purposes to trace the validation process.
class LoggingContext {
  /// The buffer that accumulates the log messages.
  final StringBuffer buffer = StringBuffer();

  /// Whether logging is enabled.
  bool enabled;

  /// Creates a new logging context.
  ///
  /// Logging is disabled by default.
  LoggingContext({this.enabled = false});

  /// Logs a message to the buffer if logging is enabled.
  void log(String message) {
    if (enabled) {
      buffer.writeln(message);
    }
  }
}
