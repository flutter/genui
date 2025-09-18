// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:travel_app/src/asset_images.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'assetImageCatalogJson should return a valid and non-empty JSON object',
    () async {
      final result = await assetImageCatalogJson();
      final decoded = jsonDecode(result);
      expect(decoded, isA<List<dynamic>>());
      expect(decoded, isNotEmpty);
    },
  );
}
