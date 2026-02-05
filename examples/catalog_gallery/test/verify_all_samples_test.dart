// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:catalog_gallery/sample_parser.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'All samples in samples/ directory should parse without error',
    () async {
      const fs = LocalFileSystem();
      // Assuming the test runs from the project root or we need to find it.
      // Flutter test usually runs from project root.
      final Directory samplesDir = fs.directory('samples');

      if (!samplesDir.existsSync()) {
        fail(
          'samples directory not found at ${samplesDir.path} '
          '(absolute: ${samplesDir.absolute.path})',
        );
      }

      final List<File> files = samplesDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.sample'))
          .toList();

      for (final file in files) {
        try {
          print('Parsing ${file.path}...');
          await SampleParser.parseFile(file);
        } catch (e, s) {
          fail('Failed to parse ${file.path}: $e\n$s');
        }
      }
    },
  );
}
