// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

/// A schema cache that supports reading files from the local file system.
///
/// This implementation is used on platforms that have access to `dart:io`.
class SchemaCacheFileLoader {
  /// Creates a new file-aware schema cache.
  Future<String> getFile(Uri uri) async {
    assert(uri.scheme == 'file');
    final file = File.fromUri(uri);
    return file.readAsString();
  }
}
