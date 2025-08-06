// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:travel_app/src/asset_images.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('assetImageCatalogJson should return valid json', () async {
    final result = await assetImageCatalogJson();
    jsonDecode(result);
  });
}
