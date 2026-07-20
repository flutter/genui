// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../test_infra/golden_texts.dart';
import '../test_infra/mock_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(setUpMockPackageAssets);

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
      final PromptBuilder chatBuilder = PromptBuilder.chat(
        catalog: testCatalog,
        systemPromptFragments: systemPromptFragments,
      );
      final PromptBuilder customBuilder = PromptBuilder.custom(
        catalog: testCatalog,
        allowedOperations: SurfaceOperations.createOnly(dataModel: false),
        systemPromptFragments: systemPromptFragments,
      );
      expect(chatBuilder.systemPrompt(), customBuilder.systemPrompt());
    });

    test('defaults to full-schema catalog prompt mode', () {
      final String prompt = PromptBuilder.chat(
        catalog: testCatalog,
      ).systemPromptJoined();

      expect(prompt, contains('COMMON_TYPES'));
      expect(prompt, contains('CATALOG_SCHEMA'));
      expect(prompt, contains('MESSAGE_SCHEMA'));
      expect(prompt, isNot(contains('A2UI_CATALOG_MANIFEST')));
    });

    test('custom prompts also default to full-schema catalog prompt mode', () {
      final String prompt = PromptBuilder.custom(
        catalog: testCatalog,
        allowedOperations: SurfaceOperations.createOnly(dataModel: false),
      ).systemPromptJoined();

      expect(prompt, contains('COMMON_TYPES'));
      expect(prompt, contains('CATALOG_SCHEMA'));
      expect(prompt, contains('MESSAGE_SCHEMA'));
      expect(prompt, isNot(contains('A2UI_CATALOG_MANIFEST')));
    });
  });

  group('Incremental catalog prompt mode', () {
    final systemPromptFragments = <String>['You are a chat assistant.'];

    String incrementalPromptFor(Catalog catalog) => PromptBuilder.chat(
      catalog: catalog,
      systemPromptFragments: systemPromptFragments,
      catalogPromptMode: CatalogPromptMode.incremental,
    ).systemPromptJoined();

    test('includes a catalog manifest section and omits the full schema', () {
      final String prompt = incrementalPromptFor(testCatalog);

      expect(prompt, contains('A2UI_CATALOG_MANIFEST'));
      expect(prompt, isNot(contains('CATALOG_SCHEMA')));
    });

    test('custom prompts can use incremental catalog prompt mode', () {
      final String prompt = PromptBuilder.custom(
        catalog: testCatalog,
        allowedOperations: SurfaceOperations.createOnly(dataModel: false),
        catalogPromptMode: CatalogPromptMode.incremental,
      ).systemPromptJoined();

      expect(prompt, contains('A2UI_CATALOG_MANIFEST'));
      expect(prompt, contains('loadCatalogItems'));
      expect(prompt, isNot(contains('CATALOG_SCHEMA')));
    });

    test('describes the required A2UI message envelope', () {
      final catalogWithoutPromptFragments = Catalog([
        BasicCatalogItems.text,
      ], catalogId: 'minimal_catalog');
      final String prompt = PromptBuilder.chat(
        catalog: catalogWithoutPromptFragments,
        catalogPromptMode: CatalogPromptMode.incremental,
      ).systemPromptJoined();

      expect(prompt, contains('top-level JSON object'));
      expect(prompt, contains('"version": "v0.9"'));
      expect(prompt, contains('message payload'));
    });

    test('uses active manifest names in the loadCatalogItems example', () {
      final textOnlyCatalog = Catalog([
        BasicCatalogItems.text,
      ], catalogId: 'text_only_catalog');
      final String prompt = incrementalPromptFor(textOnlyCatalog);

      expect(prompt, contains('loadCatalogItems'));
      expect(prompt, contains('{"items": ["Text"]}'));
      expect(prompt, isNot(contains('{"items": ["Card", "Text"]}')));
    });

    test('describes the component envelope (id and component)', () {
      final String prompt = incrementalPromptFor(testCatalog);

      expect(prompt, contains('id:'));
      expect(prompt, contains('component:'));
      expect(prompt, contains('"root"'));
    });

    test('auto-injects the loadCatalogItems carve-out policy', () {
      final String prompt = incrementalPromptFor(testCatalog);

      expect(prompt, contains(PromptFragments.incrementalCatalogToolPolicy()));
      expect(prompt, contains('context loading, not UI generation'));
    });

    test('omits the blanket no-tools restriction', () {
      final String prompt = incrementalPromptFor(testCatalog);

      expect(
        prompt,
        isNot(contains('do not have the ability to use tools for UI')),
      );
      expect(
        prompt,
        isNot(contains('do not have the ability to use function calls')),
      );
    });

    test('keeps unrelated technical restrictions', () {
      final String prompt = incrementalPromptFor(testCatalog);

      expect(prompt, contains('do not have the ability to execute code'));
    });

    test('full-schema mode still keeps the no-tools restriction', () {
      final String prompt = PromptBuilder.chat(
        catalog: testCatalog,
      ).systemPromptJoined();

      expect(prompt, contains('do not have the ability to use tools for UI'));
    });

    test('still includes surface operation instructions', () {
      final String prompt = incrementalPromptFor(testCatalog);

      expect(prompt, contains(ProtocolMessages.createSurface.name));
      expect(prompt, contains(ProtocolMessages.updateComponents.name));
    });

    test('preserves caller-provided system prompt fragments', () {
      final String prompt = incrementalPromptFor(testCatalog);

      for (final fragment in systemPromptFragments) {
        expect(prompt, contains(fragment));
      }
    });

    test('includes the client data model when provided', () {
      final String prompt = PromptBuilder.chat(
        catalog: testCatalog,
        catalogPromptMode: CatalogPromptMode.incremental,
        clientDataModel: {'foo': 'bar'},
      ).systemPromptJoined();

      expect(prompt, contains('Client Data Model:'));
      expect(prompt, contains('"foo": "bar"'));
    });

    test('throws when incremental + create has no catalogId', () {
      final anonymousCatalog = Catalog([BasicCatalogItems.text]);

      expect(
        () => PromptBuilder.chat(
          catalog: anonymousCatalog,
          catalogPromptMode: CatalogPromptMode.incremental,
        ).systemPrompt(),
        throwsStateError,
      );
    });

    test('matches the golden for the test catalog', () {
      final String prompt = PromptBuilder.chat(
        catalog: testCatalog,
        catalogPromptMode: CatalogPromptMode.incremental,
      ).systemPromptJoined();
      verifyGoldenText(prompt, 'incremental_test_catalog.txt');
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
      test(b.key, () async {
        final SurfaceOperations operations = b.value;

        final String prompt = PromptBuilder.custom(
          catalog: testCatalog,
          allowedOperations: operations,
          systemPromptFragments: systemPromptFragments,
        ).systemPromptJoined();

        for (final fragment in systemPromptFragments) {
          expect(prompt, contains(fragment));
        }

        for (final ProtocolMessages message in ProtocolMessages.values) {
          expect(prompt, contains(message.name));
        }

        final allowedMessages = <ProtocolMessages>{};

        if (operations.create) {
          allowedMessages.addAll([
            ProtocolMessages.createSurface,
            ProtocolMessages.updateComponents,
          ]);
        }
        if (operations.update) {
          allowedMessages.add(ProtocolMessages.updateComponents);
        }
        if (operations.delete) {
          allowedMessages.add(ProtocolMessages.deleteSurface);
        }
        if (operations.dataModel) {
          allowedMessages.add(ProtocolMessages.updateDataModel);
        }

        for (final ProtocolMessages message in ProtocolMessages.values) {
          if (allowedMessages.contains(message)) {
            expect(prompt, contains(message.name), reason: b.key);
          } else {
            // TODO: remove this check when examples will stop containing
            // not supported operations.
            if (!b.key.contains('_with_dataModel_false') &&
                !b.key.contains('only') &&
                !b.key.contains('create_and_update')) {
              expect(prompt, isNot(contains(message.name)), reason: b.key);
            }
          }
        }

        if (allowedMessages.contains(ProtocolMessages.createSurface)) {
          expect(prompt, contains('unique `surfaceId`'));
        }

        if (allowedMessages.contains(ProtocolMessages.updateComponents)) {
          expect(prompt, contains('root'));
        }

        verifyGoldenText(prompt, '${b.key}.txt');
      });
    }
  });

  group('Prompt with functions', () {
    test('includes functions when catalog has functions', () async {
      final catalogWithFunctions = Catalog(
        [BasicCatalogItems.text],
        functions: [BasicFunctions.pluralizeFunction],
        catalogId: 'test_catalog',
      );

      final String prompt = PromptBuilder.chat(
        catalog: catalogWithFunctions,
      ).systemPromptJoined();

      expect(prompt, contains('pluralize'));
      expect(
        prompt,
        contains(
          'Returns a localized string based on the Common Locale Data '
          'Repository',
        ),
      );
    });
  });

  group('Prompt with custom components', () {
    test('includes custom component schema in prompt', () async {
      final customItem = CatalogItem(
        name: 'CustomCard',
        dataSchema: S.object(
          properties: {
            'title': A2uiSchemas.stringReference(),
            'elevation': S.number(description: 'Card elevation.'),
          },
          required: ['title'],
        ),
        widgetBuilder: (ctx) => const SizedBox(), // Dummy builder
      );

      final customCatalog = Catalog([customItem], catalogId: 'custom_catalog');

      final String prompt = PromptBuilder.chat(
        catalog: customCatalog,
      ).systemPromptJoined();

      expect(prompt, contains('CustomCard'));
      expect(prompt, contains('Card elevation.'));
      expect(prompt, contains('"title"'));
    });
  });

  group('Catalog ID', () {
    test('is surfaced in system prompt when provided', () async {
      final catalog = Catalog([
        BasicCatalogItems.text,
      ], catalogId: 'my_custom_catalog');
      final PromptBuilder builder = PromptBuilder.chat(catalog: catalog);
      final String prompt = builder.systemPromptJoined();
      expect(prompt, contains('The active catalog ID is: "my_custom_catalog"'));
    });

    test('is not surfaced in system prompt when not provided', () async {
      final catalog = Catalog([BasicCatalogItems.text]);
      final PromptBuilder builder = PromptBuilder.chat(catalog: catalog);
      final String prompt = builder.systemPromptJoined();
      expect(prompt, isNot(contains('The active catalog ID is:')));
    });
  });
}
