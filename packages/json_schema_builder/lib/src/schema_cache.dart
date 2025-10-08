// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'exceptions.dart';
import 'logging_context.dart';
import 'schema/schema.dart';
import 'schema_cache_web.dart' if (dart.library.io) 'schema_cache_file.dart';

class SchemaCache {
  final http.Client? _externalHttpClient;
  http.Client? _internalHttpClient;
  final Map<String, Schema> _cache = {};
  final LoggingContext? _loggingContext;
  final SchemaCacheFileLoader _fileLoader = SchemaCacheFileLoader();

  SchemaCache({http.Client? httpClient, LoggingContext? loggingContext})
    : _internalHttpClient = null,
      _loggingContext = loggingContext,
      _externalHttpClient = httpClient;

  http.Client get _httpClient =>
      _externalHttpClient ?? (_internalHttpClient ??= http.Client());

  void close() {
    _internalHttpClient?.close();
  }

  Future<Schema?> get(Uri uri) async {
    final uriString = uri.toString();
    if (_cache.containsKey(uriString)) {
      return _cache[uriString];
    }

    try {
      String content;
      if (uri.scheme == 'file') {
        content = await _fileLoader.getFile(uri);
      } else if (uri.scheme == 'http' || uri.scheme == 'https') {
        final response = await _httpClient.get(uri);
        if (response.statusCode != 200) {
          throw SchemaFetchException(
            uri,
            'Failed to fetch schema: ${response.statusCode}',
          );
        }
        content = response.body;
      } else {
        // Unsupported scheme
        throw SchemaFetchException(uri, 'Unsupported scheme: ${uri.scheme}');
      }

      final schema = Schema.fromMap(
        jsonDecode(content) as Map<String, Object?>,
      );
      _cache[uriString] = schema;
      return schema;
    } catch (e) {
      _loggingContext?.log('Error fetching remote schema from $uri: $e');
      throw SchemaFetchException(uri, e);
    }
  }
}
