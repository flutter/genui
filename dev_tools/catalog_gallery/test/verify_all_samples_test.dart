// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:catalog_gallery/sample_parser.dart';
import 'package:file/file.dart';
import 'package:flutter_test/flutter_test.dart';

import 'src/sample_locator.dart';

void main() {
  test(
    'All samples in samples/ directory should parse without error',
    () async {
      final Directory? samplesDir = findSamplesDir();

      if (samplesDir == null) {
        fail('samples directory not found');
      }

      final List<File> files = samplesDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.sample'))
          .toList();

      for (final file in files) {
        try {
          await SampleParser.parseFile(file);
        } catch (exception, stackTrace) {
          fail('Failed to parse ${file.path}: $exception\n$stackTrace');
        }
      }
    },
  );
}
