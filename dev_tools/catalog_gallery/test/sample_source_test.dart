// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:catalog_gallery/sample_source.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AssetSampleSource', () {
    test('listSamples loads and parses samples from asset bundle', () async {
      final TestDefaultBinaryMessenger binaryMessenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

      // Mock AssetManifest.bin
      final manifestData = {
        'samples/hello.sample': [
          {'asset': 'samples/hello.sample'},
        ],
        'samples/world.sample': [
          {'asset': 'samples/world.sample'},
        ],
        'other/file.txt': [
          {'asset': 'other/file.txt'},
        ],
      };

      final ByteData manifestByteData = const StandardMessageCodec()
          .encodeMessage(manifestData)!;

      binaryMessenger.setMockMessageHandler('flutter/assets', (
        ByteData? message,
      ) async {
        final String key = utf8.decode(message!.buffer.asUint8List());
        if (key == 'AssetManifest.bin' || key == 'AssetManifest.json') {
          return manifestByteData;
        }
        if (key == 'samples/hello.sample') {
          return ByteData.view(utf8.encode('hello content').buffer);
        }
        if (key == 'samples/world.sample') {
          return ByteData.view(utf8.encode('world content').buffer);
        }
        return null;
      });

      addTearDown(() {
        binaryMessenger.setMockMessageHandler('flutter/assets', null);
      });

      const source = AssetSampleSource();
      final List<SampleRef> samples = await source.listSamples();

      expect(samples, hasLength(2));
      expect(samples[0].name, 'hello');
      expect(await samples[0].load(), 'hello content');
      expect(samples[1].name, 'world');
      expect(await samples[1].load(), 'world content');
    });
  });
}
