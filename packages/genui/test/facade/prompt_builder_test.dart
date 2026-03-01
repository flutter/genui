// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

void main() {
  final testCatalog = Catalog([
    BasicCatalogItems.button,
    BasicCatalogItems.text,
  ], catalogId: 'test_catalog');

  group('Chat prompt', () {
    test('is equivalent to custom prompt with create only operations', () {
      final chatBuilder = PromptBuilder.chat(catalog: testCatalog);
      final customBuilder = PromptBuilder.custom(
        catalog: testCatalog,
        allowedOperations: SurfaceOperations.createOnly(),
      );
      expect(chatBuilder.systemPrompt(), customBuilder.systemPrompt());
    });
  });

  group('Prompt contains right parts', () {
    test('create only', () {
      final builder = PromptBuilder.chat(catalog: testCatalog);
    });

    test('create only', () {
      final builder = PromptBuilder.chat(catalog: testCatalog);
    });

    test('custom prompt - update only', () {
      final builder = PromptBuilder.custom(
        catalog: const Catalog([]),
        allowedOperations: SurfaceOperations.updateOnly(),
      );
    });

    test('custom prompt - create and update', () {
      final builder = PromptBuilder.custom(
        catalog: const Catalog([]),
        allowedOperations: SurfaceOperations.createAndUpdate(),
      );
    });

    test('custom prompt - all', () {
      final builder = PromptBuilder.custom(
        catalog: const Catalog([]),
        allowedOperations: SurfaceOperations.all(),
      );
    });
  });
}
