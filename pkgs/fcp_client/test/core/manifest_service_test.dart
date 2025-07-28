import 'dart:convert';
import 'package:fcp_client/fcp_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ManifestService', () {
    final service = ManifestService();
    final validJsonString = '''
      {
        "manifestVersion": "1.0.0",
        "dataTypes": {},
        "widgets": {
          "Text": {
            "properties": {
              "data": { "type": "String", "isRequired": true }
            }
          }
        }
      }
    ''';
    final invalidJsonString =
        '{"manifestVersion": "1.0.0", "widgets": "not a map"}';

    group('parse', () {
      test('parses valid JSON string into a WidgetLibraryManifest', () {
        final manifest = service.parse(validJsonString);
        expect(manifest, isA<WidgetLibraryManifest>());
        expect(manifest.manifestVersion, '1.0.0');
        expect(manifest.widgets.keys, contains('Text'));
      });

      test('throws FormatException for invalid JSON structure', () {
        // The getter 'widgets' should throw a TypeError when it tries to cast
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

      test('loads and parses a manifest from assets', () async {
        mockAssetHandler((message) async {
          final key = utf8.decode(message!.buffer.asUint8List());
          if (key == 'assets/test_manifest.json') {
            return ByteData.sublistView(utf8.encoder.convert(validJsonString));
          }
          return null;
        });

        final manifest = await service.loadFromAssets(
          'assets/test_manifest.json',
        );
        expect(manifest, isA<WidgetLibraryManifest>());
        expect(manifest.manifestVersion, '1.0.0');
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
