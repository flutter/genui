// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

void main() {
  group('GenUiEngine Validation', () {
    test('CreateSurface fails validation with empty surfaceId', () async {
      final processor = GenUiEngine(catalogs: []);

      // Expect an error message on the submit stream
      final Future<void> future = expectLater(
        processor.onSubmit,
        emits(
          predicate((ChatMessage message) {
            final UiInteractionPart part =
                message.parts.uiInteractionParts.first;
            final json = jsonDecode(part.interaction) as Map<String, dynamic>;
            final error = json['error'] as Map<String, dynamic>;
            return error['code'] == 'VALIDATION_FAILED' &&
                error['path'] == 'surfaceId';
          }),
        ),
      );

      processor.handleMessage(
        const CreateSurface(surfaceId: '', catalogId: 'default'),
      );

      await future;
    });
  });
}
