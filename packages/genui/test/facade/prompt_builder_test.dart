// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

import '../test_infra/golden_texts.dart';

void main() {
  final testCatalog = Catalog(
    [BasicCatalogItems.text],
    catalogId: 'test_catalog',
    systemPromptFragments: [
      BasicCatalogItems.basicCatalogRules,
      PromptFragments.acknowledgeUser(),
      PromptFragments.requireAtLeastOneSubmitElement(
        prefix: PromptBuilder.defaultImportancePrefix,
      ),
    ],
  );

  group('Chat prompt', () {
    test('is equivalent to custom prompt with create only operations', () {
      final systemPromptFragments = [
        'You are a chat assistant.',
        'You sometimes tell jokes to the user',
      ];
      final chatBuilder = PromptBuilder.chat(
        catalog: testCatalog,
        systemPromptFragments: systemPromptFragments,
      );
      final customBuilder = PromptBuilder.custom(
        catalog: testCatalog,
        allowedOperations: SurfaceOperations.createOnly(dataModel: false),
        systemPromptFragments: systemPromptFragments,
      );
      expect(chatBuilder.systemPrompt(), customBuilder.systemPrompt());
    });
  });

  group('Custom prompt', () {
    final systemPromptFragments = <String>[
      'You are a helpful assistant who chats with a user.',
      PromptFragments.acknowledgeUser(),
      PromptFragments.requireAtLeastOneSubmitElement(
        prefix: PromptBuilder.defaultImportancePrefix,
      ),
    ];

    final Map<String, SurfaceOperations> operationsUnderTheTest = {};
    for (final dataModel in [false, true]) {
      operationsUnderTheTest['create_only_with_dataModel_$dataModel'] =
          SurfaceOperations.createOnly(dataModel: dataModel);
      operationsUnderTheTest['update_only_with_dataModel_$dataModel'] =
          SurfaceOperations.updateOnly(dataModel: dataModel);
      operationsUnderTheTest['create_and_update_with_dataModel_$dataModel'] =
          SurfaceOperations.createAndUpdate(dataModel: dataModel);
      operationsUnderTheTest['all_operations_with_dataModel_$dataModel'] =
          SurfaceOperations.all(dataModel: dataModel);
    }

    for (MapEntry<String, SurfaceOperations> b
        in operationsUnderTheTest.entries) {
      test(b.key, () {
        final String prompt = PromptBuilder.custom(
          catalog: testCatalog,
          allowedOperations: b.value,
          systemPromptFragments: systemPromptFragments,
        ).systemPromptJoined();

        verifyGoldenText(prompt, '${b.key}.txt');
      });
    }
  });
}
