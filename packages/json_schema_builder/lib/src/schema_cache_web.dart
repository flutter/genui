// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class SchemaCacheFileLoader {
  Future<String> getFile(Uri uri) async {
    throw UnimplementedError(
      'file:// schemes not supported for schema cache on web.',
    );
  }
}
