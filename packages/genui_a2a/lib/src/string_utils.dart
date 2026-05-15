// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Builds a `toString` style string for a class.
///
/// Example: `buildToString('Message', {'id': 1, 'name': 'foo'})`
/// returns `'Message(id: 1, name: foo)'`.
String buildToString(String className, Map<String, Object?> fields) {
  final buffer = StringBuffer(className)..write('(');
  var first = true;
  fields.forEach((name, value) {
    if (!first) buffer.write(', ');
    buffer.write('$name: $value');
    first = false;
  });
  buffer.write(')');
  return buffer.toString();
}
