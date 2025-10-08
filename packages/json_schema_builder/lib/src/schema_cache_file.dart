// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'schema_cache_base.dart';

class SchemaCache extends SchemaCacheBase {
  SchemaCache({super.httpClient, super.loggingContext});

  @override
  Future<String> getCachedFile(Uri uri) async {
    assert(uri.scheme == 'file');
    final file = File.fromUri(uri);
    return file.readAsString();
  }
}
