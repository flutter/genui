// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:travel_app/src/asset_images.dart';

void main() {
  test(
    'images.json should contain all images from assets/travel_images',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();

      final String imageAssets = await assetImageCatalogJson();
      final List<String> imageList = (jsonDecode(imageAssets) as List)
          .map((e) => (e as Map<String, Object?>).values.first as String)
          .toList();

      final imageDir = Directory(assetImageCatalogPath);
      final List<String> imageFiles = imageDir
          .listSync()
          .where((file) => file.path != assetImageCatalogJsonFile)
          .map((file) => file.path)
          .toList();

      expect(imageList, unorderedEquals(imageFiles));
    },
  );
}
