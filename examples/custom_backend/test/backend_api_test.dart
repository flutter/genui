// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:custom_backend/backend.dart';
import 'package:custom_backend/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

void main() {
  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
  });

  for (final String? savedResponse in savedResponseAssets) {
    // TODO: fix Gemini API keys to get live test working.
    if (savedResponse == null) {
      continue;
    }

    // To update the saved responses, run the app, select "Request Gemini",
    // and copy the console output of the "full-response" to the
    // corresponding `saved-response-X.json` file in `assets/data/`.
    test(
      'sendRequest works for $savedResponse',
      () async {
        final protocol = Backend(uiSchema);
        final ParsedToolCall? result = await protocol.sendRequest(
          requestText,
          savedResponse: savedResponse,
        );
        expect(result, isNotNull);
        expect(result!.messages.length, 2);
        expect(result.messages[0], isA<UpdateComponents>());
        expect(result.messages[1], isA<CreateSurface>());
      },
      retry: 3,
      timeout: const Timeout(Duration(minutes: 2)),
    );
  }
}
