// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dart_schema_builder/src/schema/schema.dart';
import 'package:dart_schema_builder/src/schema_cache.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'schema_cache_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('SchemaCache', () {
    late SchemaCache schemaCache;
    late MockClient mockHttpClient;

    setUp(() {
      mockHttpClient = MockClient();
      schemaCache = SchemaCache(httpClient: mockHttpClient);
    });

    test('fetches and caches a schema from a file URI', () async {
      final tempFile = File('temp_schema.json')..createSync();
      await tempFile.writeAsString(jsonEncode({'type': 'string'}));
      final uri = tempFile.absolute.uri;

      final schema = await schemaCache.get(uri);

      expect(schema?.value, equals({'type': 'string'}));

      // Verify it's cached
      final cachedSchema = await schemaCache.get(uri);
      expect(cachedSchema, same(schema));

      await tempFile.delete();
    });

    test('fetches and caches a schema from an HTTP URI', () async {
      final uri = Uri.parse('http://example.com/schema.json');
      final schemaJson = {'type': 'number'};
      final responseBody = jsonEncode(schemaJson);

      when(
        mockHttpClient.get(uri),
      ).thenAnswer((_) async => http.Response(responseBody, 200));

      final schema = await schemaCache.get(uri);

      expect(schema, isA<Schema>());
      expect(schema!.type, 'number');

      // Verify it's cached
      final cachedSchema = await schemaCache.get(uri);
      expect(cachedSchema, same(schema));
    });

    test('returns null for unsupported URI schemes', () async {
      final uri = Uri.parse('ftp://example.com/schema.json');
      final schema = await schemaCache.get(uri);
      expect(schema, isNull);
    });

    test('returns null for non-existent file URI', () async {
      final uri = Uri.parse('file:///non/existent/file.json');
      final schema = await schemaCache.get(uri);
      expect(schema, isNull);
    });

    test('returns null for failed HTTP request', () async {
      final uri = Uri.parse('http://example.com/schema.json');
      when(
        mockHttpClient.get(uri),
      ).thenAnswer((_) async => http.Response('Not Found', 404));
      final schema = await schemaCache.get(uri);
      expect(schema, isNull);
    });
  });
}
