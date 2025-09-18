// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:logging/logging.dart';

/// The logger for the GenUI package.
final genUiLogger = Logger('GenUI');

/// Configures the logging for the GenUI package.
///
/// This function should be called by applications using the GenUI package to
/// configure the desired log level and to listen for log messages.
Logger configureGenUiLogging({
  Level level = Level.INFO,
  void Function(Level, String)? logCallback,
}) {
  logCallback ??= (level, message) {
    // ignore: avoid_print
    print(message);
  };
  hierarchicalLoggingEnabled = true;
  recordStackTraceAtLevel = Level.SEVERE;
  genUiLogger.level = level;
  Logger.root.onRecord.listen((record) {
    if (record.loggerName == genUiLogger.name) {
      logCallback?.call(
        record.level,
        '[${record.level.name}] ${record.time}: ${record.message}',
      );
      if (record.error != null) {
        logCallback?.call(record.level, '  Error: ${record.error}');
      }
      if (record.stackTrace != null) {
        logCallback?.call(record.level, '  Stack trace:\n${record.stackTrace}');
      }
    }
  });

  return genUiLogger;
}
