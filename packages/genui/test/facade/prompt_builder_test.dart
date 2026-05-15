// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../test_infra/golden_texts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Mock asset loading because PromptBuilder loads schemas from assets,
    // and Flutter tests do not load package assets automatically.
    // This handler intercepts requests for assets and loads them directly
    // from the local file system.
    // It handles different CWDs (running from package root or example
    // directory).
    final String cwd = Directory.current.path;
    String packageRoot;
    if (cwd.endsWith('packages/genui')) {
      packageRoot = cwd;
    } else if (cwd.contains('examples/')) {
      packageRoot =
          '${cwd.substring(0, cwd.indexOf('examples/'))}packages/genui';
    } else {
      packageRoot = '$cwd/packages/genui';
    }

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
          final String key = utf8.decode(message!.buffer.asUint8List());
          var relativePath = key;
          if (key.startsWith('packages/genui/')) {
            relativePath = key.substring('packages/genui/'.length);
          }
          final file = File('$packageRoot/$relativePath');
          if (file.existsSync()) {
            return ByteData.view(utf8.encode(file.readAsStringSync()).buffer);
          }
          return null;
        });
  });

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
    test(
      'is equivalent to custom prompt with create only operations',
      () async {
        final systemPromptFragments = [
          'You are a chat assistant.',
          'You sometimes tell jokes to the user',
        ];
        final PromptBuilder chatBuilder = await PromptBuilder.createChat(
          catalog: testCatalog,
          systemPromptFragments: systemPromptFragments,
        );
        final PromptBuilder customBuilder = await PromptBuilder.createCustom(
          catalog: testCatalog,
          allowedOperations: SurfaceOperations.createOnly(dataModel: false),
          systemPromptFragments: systemPromptFragments,
        );
        expect(chatBuilder.systemPrompt(), customBuilder.systemPrompt());
      },
    );
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

        final String prompt = (await PromptBuilder.createCustom(
          catalog: testCatalog,
          allowedOperations: operations,
          systemPromptFragments: systemPromptFragments,
        )).systemPromptJoined();

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

      final String prompt = (await PromptBuilder.createChat(
        catalog: catalogWithFunctions,
      )).systemPromptJoined();

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

      final String prompt = (await PromptBuilder.createChat(
        catalog: customCatalog,
      )).systemPromptJoined();

      expect(prompt, contains('CustomCard'));
      expect(prompt, contains('Card elevation.'));
      expect(prompt, contains('"title"'));
    });
  });
}
