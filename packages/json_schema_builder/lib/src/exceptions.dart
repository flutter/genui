// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class SchemaFetchException implements Exception {
  final Uri uri;
  final Object? cause;

  SchemaFetchException(this.uri, [this.cause]);

  @override
  String toString() {
    var message = 'Error fetching remote schema from $uri';
    if (cause != null) {
      message = '$message: $cause';
    }
    return message;
  }
}
