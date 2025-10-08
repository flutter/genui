// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'schema_cache.dart';

class SchemaCache extends SchemaCacheBase {
  SchemaCache({super.httpClient});

  @override
  Future<String> getCachedFile(Uri uri) async {
    if (uri.scheme == 'file') {
      final file = File.fromUri(uri);
      return file.readAsStringSync();
    }
    throw ArgumentError('Unsupported scheme: ${uri.scheme}');
  }
}
