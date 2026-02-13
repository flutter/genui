// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui/src/facade/prompt_builder.dart';

void main() {
  group('PromptBuilder', () {
    const String instructions = 'These are some instructions.';
    final catalog = Catalog([]); // Empty catalog for testing.

    test('includes instructions when provided', () {
      final builder = PromptBuilder(
        catalog: catalog,
        instructions: instructions,
      );

      expect(builder.prompt, contains(instructions));
    });

    test('includes warning about surfaceId', () {
      final builder = PromptBuilder(catalog: catalog);

      expect(builder.prompt, contains('IMPORTANT: When you generate UI'));
      expect(builder.prompt, contains('surfaceId'));
    });

    test('includes A2UI schema', () {
      final builder = PromptBuilder(catalog: catalog);

      expect(builder.prompt, contains('<a2ui_schema>'));
      expect(builder.prompt, contains('</a2ui_schema>'));
    });

    test('includes standard catalog rules', () {
      final builder = PromptBuilder(catalog: catalog);

      expect(
        builder.prompt,
        contains(StandardCatalogEmbed.standardCatalogRules),
      );
    });

    test('includes basic chat prompt fragment', () {
      final builder = PromptBuilder(catalog: catalog);

      expect(builder.prompt, contains('# Outputting UI information'));
    });
  });
}
