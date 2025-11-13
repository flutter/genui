// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class ReleaseException implements Exception {
  final String message;

  ReleaseException(this.message);

  @override
  String toString() => message;
}
