// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';

import 'test_infra/io_get_api_key.dart';

void main() {
  test('smoke test', () {
    final String key = apiKey();
    expect(key, isNotEmpty);
    print('API Key: ${key.substring(0, 2)}...${key.substring(key.length - 2)}');
  });
}
