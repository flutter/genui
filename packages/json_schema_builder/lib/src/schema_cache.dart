// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:http/http.dart' as http;
import 'schema/schema.dart';

export 'schema_cache_web.dart' if (dart.library.io) 'schema_cache_file.dart';

abstract class SchemaCacheInterface {
  SchemaCacheInterface({http.Client? httpClient});

  Future<Schema?> get(Uri uri);
}
