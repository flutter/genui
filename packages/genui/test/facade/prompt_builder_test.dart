// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

void main() {
  final testCatalog = Catalog([
    BasicCatalogItems.text,
  ], catalogId: 'test_catalog');

  group('Chat prompt', () {
    test('is equivalent to custom prompt with create only operations', () {
      final systemPromptFragments = ['You are a chat assistant.'];
      final chatBuilder = PromptBuilder.chat(
        catalog: testCatalog,
        systemPromptFragments: systemPromptFragments,
      );
      final customBuilder = PromptBuilder.custom(
        catalog: testCatalog,
        allowedOperations: SurfaceOperations.createOnly(),
        systemPromptFragments: systemPromptFragments,
      );
      expect(chatBuilder.systemPrompt(), customBuilder.systemPrompt());
    });
  });

  group('Custom prompt', () {
    test('create only', () {
      final builder = PromptBuilder.chat(catalog: testCatalog);
    });

    test('update only', () {
      final builder = PromptBuilder.custom(
        catalog: testCatalog,
        allowedOperations: SurfaceOperations.updateOnly(),
      );
    });

    test('create and update', () {
      final builder = PromptBuilder.custom(
        catalog: testCatalog,
        allowedOperations: SurfaceOperations.createAndUpdate(),
      );
    });

    // test('custom prompt - all', () {
    //   final builder = PromptBuilder.custom(
    //     catalog: const Catalog([]),
    //     allowedOperations: SurfaceOperations.all(),
    //   );
    // });
  });
}
