// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'schema/schema.dart';

class SchemaCache {
  final http.Client _httpClient;
  final Map<String, Schema> _cache = {};

  SchemaCache({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  Future<Schema?> get(Uri uri) async {
    final uriString = uri.toString();
    if (_cache.containsKey(uriString)) {
      return _cache[uriString];
    }

    try {
      String content;
      if (uri.scheme == 'file') {
        final file = File.fromUri(uri);
        content = await file.readAsString();
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
