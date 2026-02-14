// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Sanitizes data for logging purposes.
///
/// This function recursively traverses the given [data] and replaces the value
/// of any key named "bytes" with the string `"&lt;binary bytes&gt;"`. This is
/// useful for preventing large binary data from cluttering log output.
Object? sanitizeLogData(Object? data) {
  if (data is Map) {
    final Map<String, Object?> sanitized = {};
    for (final MapEntry<dynamic, dynamic> entry in data.entries) {
      final key = entry.key.toString();
      if (key == 'bytes') {
        sanitized[key] = '<binary bytes>';
      } else {
        sanitized[key] = sanitizeLogData(entry.value);
      }
    }
    return sanitized;
  } else if (data is List) {
    return data.map(sanitizeLogData).toList();
  }
  return data;
}
