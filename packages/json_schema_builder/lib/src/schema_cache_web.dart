// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'schema_cache_base.dart';

class SchemaCache extends SchemaCacheBase {
  SchemaCache({super.httpClient, super.loggingContext});

  @override
  Future<String> getCachedFile(Uri uri) async {
    throw UnimplementedError(
      'file:// schemes not supported for schema cache on web.',
    );
  }
}
