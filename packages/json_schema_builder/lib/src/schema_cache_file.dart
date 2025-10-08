// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

class SchemaCacheFileLoader {
  Future<String> getFile(Uri uri) async {
    assert(uri.scheme == 'file');
    final file = File.fromUri(uri);
    return file.readAsString();
  }
}
