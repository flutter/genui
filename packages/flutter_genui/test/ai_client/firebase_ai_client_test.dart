// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_genui/src/ai_client/firebase_ai_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirebaseAiClient', () {
    test('activeRequests increments and decrements correctly', () async {
      final client = FirebaseAiClient();
      final future = client.generateText([]);
      expect(client.activeRequests.value, 1);
      try {
        await future;
      } catch (e) {
        // Ignore errors for this test.
      }
      expect(client.activeRequests.value, 0);
    });

    test('activeRequests decrements on error', () async {
      final client = FirebaseAiClient();
      final future = client.generateText([]);
      expect(client.activeRequests.value, 1);
      try {
        await future;
      } catch (e) {
        // Ignore errors for this test.
      }
      expect(client.activeRequests.value, 0);
    });
  });
}