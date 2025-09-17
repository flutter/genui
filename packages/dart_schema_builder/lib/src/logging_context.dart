// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class LoggingContext {
  final StringBuffer buffer = StringBuffer();
  bool enabled;

  LoggingContext({this.enabled = false});

  void log(String message) {
    if (enabled) {
      buffer.writeln(message);
    }
  }
}
