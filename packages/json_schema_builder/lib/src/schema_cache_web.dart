// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A schema cache that does not support reading files from the local file
/// system.
///
/// This implementation is used on the web, where file system access is not
/// available.
class SchemaCacheFileLoader {
  /// Creates a new web-based schema cache.
  Future<String> getFile(Uri uri) async {
    throw UnimplementedError(
      'file:// schemes not supported for schema cache on web.',
    );
  }
}
