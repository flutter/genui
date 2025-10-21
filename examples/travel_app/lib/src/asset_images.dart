// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

@visibleForTesting
const assetImageCatalogPath = 'assets/travel_images';
@visibleForTesting
const assetImageCatalogJsonFile = '$assetImageCatalogPath/_images.json';

/// Loads the asset image catalog from the asset bundle and prepends the asset
/// path to the image file names.
Future<String> assetImageCatalogJson() async {
  var result = await rootBundle.loadString(assetImageCatalogJsonFile);
  result = result.replaceAll(
    '"image_file_name": "',
    '"image_file_name": "$assetImageCatalogPath/',
  );
  return result;
}
