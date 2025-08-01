// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_genui/src/model/chat_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UiResponse', () {
    test('constructor generates a surfaceId if not provided', () {
      final response = UiResponse(definition: {});
      expect(response.surfaceId, isNotNull);
      expect(response.surfaceId, isNotEmpty);
    });

    test('constructor uses provided surfaceId', () {
      final response = UiResponse(definition: {}, surfaceId: 'customId');
      expect(response.surfaceId, 'customId');
    });

    test('two instances have different auto-generated surfaceIds', () {
      final response1 = UiResponse(definition: {});
      final response2 = UiResponse(definition: {});
      expect(response1.surfaceId, isNot(equals(response2.surfaceId)));
    });
  });
}
