// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'package:fcp_client/fcp_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CatalogService', () {
    final service = CatalogService();
    final validJsonString = '''
      {
        "catalogVersion": "1.0.0",
        "dataTypes": {},
        "items": {
          "Text": {
            "properties": {
              "data": { "type": "String", "isRequired": true }
            }
          }
        }
      }
    ''';
    final invalidJsonString =
        '{"catalogVersion": "1.0.0", "items": "not a map"}';

    group('parse', () {
      test('parses valid JSON string into a WidgetCatalog', () {
        final catalog = service.parse(validJsonString);
        expect(catalog, isA<WidgetCatalog>());
        expect(catalog.catalogVersion, '1.0.0');
        expect(catalog.items.keys, contains('Text'));
      });

      test('throws FormatException for invalid JSON structure', () {
        // The getter 'items' should throw a TypeError when it tries to cast
        // a String to a Map.
        expect(
          () => service.parse(invalidJsonString),
          throwsA(isA<FormatException>()),
        );
      });

      test('throws a FormatException for malformed JSON string', () {
        expect(() => service.parse('{'), throwsA(isA<FormatException>()));
      });
    });

    group('loadFromAssets', () {
      // This mock handler simulates the platform's asset loading mechanism.
      void mockAssetHandler(
        Future<ByteData?>? Function(ByteData? message) handler,
      ) {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', handler);
      }

      tearDown(() {
        // Clear the mock handler after each test.
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', null);
      });

      test('loads and parses a catalog from assets', () async {
        mockAssetHandler((message) async {
          final key = utf8.decode(message!.buffer.asUint8List());
          if (key == 'assets/test_catalog.json') {
            return ByteData.sublistView(utf8.encoder.convert(validJsonString));
          }
          return null;
        });

        final catalog = await service.loadFromAssets(
          'assets/test_catalog.json',
        );
        expect(catalog, isA<WidgetCatalog>());
        expect(catalog.catalogVersion, '1.0.0');
      });

      test('throws if asset does not exist', () async {
        // This mock handler always returns null, simulating a missing asset.
        mockAssetHandler((message) async => null);

        expect(
          () => service.loadFromAssets('assets/non_existent.json'),
          throwsA(isA<FlutterError>()),
        );
      });
    });
  });
}
