// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

@visibleForTesting
const assetImageCatalogPath = 'assets/travel_images';
@visibleForTesting
const assetImageCatalogJsonFile = '$assetImageCatalogPath/_images.json';

/// Loads the asset image catalog from the asset bundle and prepends the asset
/// path to the image file names.
Future<String> assetImageCatalogJson() async {
  final String jsonString = await rootBundle.loadString(assetImageCatalogJsonFile);
  final List<dynamic> imageList = jsonDecode(jsonString) as List<dynamic>;

  for (final item in imageList) {
    if (item is Map<String, dynamic> && item.containsKey('image_file_name')) {
      item['image_file_name'] =
          '$assetImageCatalogPath/${item['image_file_name']}';
    }
  }

  return jsonEncode(imageList);
}
