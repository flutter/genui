// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'schema/schema.dart';
import 'schema_cache.dart';

final class SchemaCache extends SchemaCacheInterface {
  final http.Client _httpClient;
  final Map<String, Schema> _cache = {};

  SchemaCache({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  @override
  Future<Schema?> get(Uri uri) async {
    final uriString = uri.toString();
    if (_cache.containsKey(uriString)) {
      return _cache[uriString];
    }

    try {
      String content;
      if (uri.scheme == 'file') {
        throw UnimplementedError(
          'file:// schemes not supported for schema cache on web.',
        );
      } else if (uri.scheme == 'http' || uri.scheme == 'https') {
        final response = await _httpClient.get(uri);
        if (response.statusCode != 200) {
          return null;
        }
        content = response.body;
      } else {
        // Unsupported scheme
        return null;
      }

      final schema = Schema.fromMap(
        jsonDecode(content) as Map<String, Object?>,
      );
      _cache[uriString] = schema;
      return schema;
    } catch (e) {
      return null;
    }
  }
}
