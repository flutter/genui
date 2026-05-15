// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/local.dart';

/// Returns the package's `samples/` directory regardless of whether tests
/// are run from the package directory, the `test/` directory, or the
/// monorepo root.
Directory? findSamplesDir() {
  const fs = LocalFileSystem();
  final Directory current = fs.currentDirectory;

  for (final candidate in <Directory>[
    current.childDirectory('samples'),
    current.childDirectory('../samples'),
    if (current.path.endsWith('/test')) current.parent.childDirectory('samples'),
    current.childDirectory('dev_tools/catalog_gallery/samples'),
  ]) {
    if (candidate.existsSync()) return candidate;
  }
  return null;
}
