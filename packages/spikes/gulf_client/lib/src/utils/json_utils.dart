// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A utility class for handling JSON parsing.
class JsonUtils {
  /// Safely parses a [value] to a [double].
  static double? parseDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }
}
