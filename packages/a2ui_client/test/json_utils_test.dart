// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_client/src/utils/json_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JsonUtils', () {
    test('parseDouble returns double for int', () {
      expect(JsonUtils.parseDouble(1), 1.0);
    });

    test('parseDouble returns double for double', () {
      expect(JsonUtils.parseDouble(1.5), 1.5);
    });

    test('parseDouble returns null for non-num', () {
      expect(JsonUtils.parseDouble('a'), isNull);
    });

    test('parseDouble returns null for null', () {
      expect(JsonUtils.parseDouble(null), isNull);
    });
  });
}
