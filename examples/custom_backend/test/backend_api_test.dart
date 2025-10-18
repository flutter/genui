// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:custom_backend/main.dart';
import 'package:custom_backend/protocol/protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
  });

  for (final savedResponse in savedResponseAssets) {
    test(
      'sendRequest works for ${savedResponse ?? 'real request'}',
      () async {
        final protocol = Protocol();
        final result = await protocol.sendRequest(
          requestText,
          savedResponse: savedResponse,
        );
        expect(result, isNotNull);
      },
      retry: 3,
      timeout: const Timeout(Duration(minutes: 2)),
    );
  }
}
