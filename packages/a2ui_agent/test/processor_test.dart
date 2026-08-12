// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_agent/a2ui_agent.dart';
import 'package:a2ui_core/a2ui_core.dart';
import 'package:test/test.dart';

void main() {
  final String minimalId = MinimalCatalog().id;

  A2uiRendererCapabilities capabilities(List<String> ids) =>
      A2uiRendererCapabilities(supportedCatalogIds: ids);

  group('A2uiRendererCapabilities', () {
    test('parses the version-keyed wire form', () {
      final capabilities = A2uiRendererCapabilities.fromJson({
        'v0.9': {
          'supportedCatalogIds': ['a', 'b'],
        },
      });

      expect(capabilities.supportedCatalogIds, ['a', 'b']);
      expect(capabilities.protocolVersion, ProtocolVersion.v09);
    });

    test('parses a bare capabilities object', () {
      final capabilities = A2uiRendererCapabilities.fromJson({
        'supportedCatalogIds': ['a'],
      });

      expect(capabilities.supportedCatalogIds, ['a']);
    });

    test('parses inline catalogs', () {
      final capabilities = A2uiRendererCapabilities.fromJson({
        'v0.9': {
          'supportedCatalogIds': <String>[],
          'inlineCatalogs': [
            {'catalogId': 'inline', 'components': <String, Object?>{}},
          ],
        },
      });

      expect(capabilities.inlineCatalogs.single['catalogId'], 'inline');
    });

    test('round trips through JSON', () {
      const capabilities = A2uiRendererCapabilities(supportedCatalogIds: ['a']);

      expect(
        A2uiRendererCapabilities.fromJson(
          capabilities.toJson(),
        ).supportedCatalogIds,
        ['a'],
      );
    });

    test('tolerates a malformed payload', () {
      final capabilities = A2uiRendererCapabilities.fromJson({
        'v0.9': {'supportedCatalogIds': 'not a list'},
      });

      expect(capabilities.supportedCatalogIds, isEmpty);
    });
  });

  group('resolveCatalogs', () {
    test('returns the transformed catalogs the renderer supports', () {
      final List<Catalog<ComponentApi>> active = resolveCatalogs([
        CatalogConfig(
          MinimalCatalog(),
          transformers: [
            ComponentPruningTransformer(const ['Text']),
          ],
        ),
      ], capabilities([minimalId]));

      expect(active.single.components.keys, ['Text']);
    });

    test('leaves out catalogs the renderer cannot render', () {
      final List<Catalog<ComponentApi>> active = resolveCatalogs([
        CatalogConfig(MinimalCatalog()),
        CatalogConfig(Catalog<ComponentApi>(id: 'other', components: const [])),
      ], capabilities([minimalId]));

      expect(active.map((catalog) => catalog.id), [minimalId]);
    });

    test('throws when nothing is shared', () {
      expect(
        () => resolveCatalogs([
          CatalogConfig(MinimalCatalog()),
        ], capabilities(['something-else'])),
        throwsA(isA<A2uiCapabilityError>()),
      );
    });

    test('loads inline catalogs when the agent accepts them', () {
      final List<Catalog<ComponentApi>> active = resolveCatalogs(
        [CatalogConfig(MinimalCatalog())],
        A2uiRendererCapabilities(
          supportedCatalogIds: [minimalId],
          inlineCatalogs: const [
            {
              'catalogId': 'inline',
              'components': {
                'Badge': {
                  'allOf': [
                    {
                      'properties': {
                        'label': {'type': 'string'},
                      },
                      'required': ['label'],
                    },
                  ],
                },
              },
            },
          ],
        ),
        acceptsInlineCatalogs: true,
      );

      expect(active.map((catalog) => catalog.id), [minimalId, 'inline']);
      expect(active[1].components.keys, ['Badge']);
    });

    test('ignores inline catalogs when the agent does not accept them', () {
      final List<Catalog<ComponentApi>> active = resolveCatalogs(
        [CatalogConfig(MinimalCatalog())],
        A2uiRendererCapabilities(
          supportedCatalogIds: [minimalId],
          inlineCatalogs: const [
            {'catalogId': 'inline', 'components': <String, Object?>{}},
          ],
        ),
      );

      expect(active, hasLength(1));
    });
  });

  group('A2uiGenerator', () {
    test('creates a processor bound to the negotiated catalogs', () {
      final generator = A2uiGenerator(
        catalogs: [
          CatalogConfig(
            MinimalCatalog(),
            transformers: [
              ComponentPruningTransformer(const ['Text', 'Column']),
            ],
          ),
        ],
      );

      final A2uiRequestProcessor processor = generator.createProcessor(
        capabilities([minimalId]),
      );

      expect(processor.activeCatalogs.single.components.keys, [
        'Text',
        'Column',
      ]);
    });

    test('defaults to the Direct JSON format', () {
      final generator = A2uiGenerator(
        catalogs: [CatalogConfig(MinimalCatalog())],
      );

      expect(
        generator.createProcessor(capabilities([minimalId])).format,
        isA<DirectJsonFormat>(),
      );
    });

    test('accepts a format override per request', () {
      final generator = A2uiGenerator(
        catalogs: [CatalogConfig(MinimalCatalog())],
      );

      final A2uiRequestProcessor processor = generator.createProcessor(
        capabilities([minimalId]),
        inferenceFormatFactory: const ExpressFormatFactory(),
      );

      expect(processor.format, isA<ExpressFormat>());
      expect(processor.createParser(), isA<ExpressParser>());
    });

    test('rejects an example that uses a pruned component', () {
      final generator = A2uiGenerator(
        catalogs: [
          CatalogConfig(
            MinimalCatalog(),
            transformers: [
              ComponentPruningTransformer(const ['Text']),
            ],
          ),
        ],
        examples: {
          'uses a button': [
            UpdateComponentsMessage(
              surfaceId: 's',
              components: [
                {'id': 'root', 'component': 'Button'},
              ],
            ),
          ],
        },
      );

      expect(
        () => generator.createProcessor(capabilities([minimalId])),
        throwsA(
          isA<A2uiValidationError>().having(
            (error) => error.message,
            'message',
            allOf(contains('uses a button'), contains('Button')),
          ),
        ),
      );
    });

    test('accepts an example that conforms', () {
      final generator = A2uiGenerator(
        catalogs: [CatalogConfig(MinimalCatalog())],
        examples: {
          'a greeting': [
            CreateSurfaceMessage(surfaceId: 's', catalogId: minimalId),
            UpdateComponentsMessage(
              surfaceId: 's',
              components: [
                {'id': 'root', 'component': 'Text', 'text': 'Hi'},
              ],
            ),
          ],
        },
      );

      expect(
        generator.createProcessor(capabilities([minimalId])).examples,
        isNotNull,
      );
    });

    test('reports the catalogs it supports', () {
      final generator = A2uiGenerator(
        catalogs: [CatalogConfig(MinimalCatalog())],
      );

      expect(generator.supportedCapabilities.supportedCatalogIds, [minimalId]);
    });
  });

  group('A2uiRequestProcessor', () {
    A2uiRequestProcessor processor({InferenceFormatFactory? factory}) =>
        A2uiRequestProcessor(
          catalogs: [MinimalCatalog()],
          formatFactory: factory,
        );

    test('renders a prompt snippet describing the catalogs', () {
      final String snippet = processor().promptSnippet;

      expect(snippet, contains('<a2ui-json>'));
      expect(snippet, contains('<a2ui_schema>'));
      expect(snippet, contains('"Text"'));
      expect(snippet, contains(MinimalCatalog().id));
    });

    test('caches the prompt snippet', () {
      final A2uiRequestProcessor subject = processor();

      expect(identical(subject.promptSnippet, subject.promptSnippet), isTrue);
    });

    test('renders Express signatures when that format is used', () {
      final String snippet = processor(
        factory: const ExpressFormatFactory(),
      ).promptSnippet;

      expect(snippet, contains('<a2ui-express>'));
      expect(snippet, contains('Text(text: DynamicString'));
      expect(snippet, contains('capitalize(value: DynamicString) -> string'));
    });

    test('renders examples in the prompt', () {
      final subject = A2uiRequestProcessor(
        catalogs: [MinimalCatalog()],
        examples: {
          'a greeting': [
            UpdateComponentsMessage(
              surfaceId: 's',
              components: [
                {'id': 'root', 'component': 'Text', 'text': 'Hi'},
              ],
            ),
          ],
        },
      );

      expect(subject.promptSnippet, contains('a greeting'));
      expect(subject.promptSnippet, contains('"Hi"'));
    });

    test('gives each turn its own parser', () {
      final A2uiRequestProcessor subject = processor();

      expect(
        identical(subject.createParser(), subject.createParser()),
        isFalse,
      );
    });

    test('parses and validates a response', () {
      final List<ResponsePart> parts = processor().parseResponse(
        'Sure.<a2ui-json>[{"version":"v0.9","updateComponents":'
        '{"surfaceId":"s","components":[{"id":"root","component":"Text",'
        '"text":"Hi"}]}}]</a2ui-json>',
      );

      expect(parts.first, const TextPart('Sure.'));
      expect(
        (parts[1] as A2uiPart).a2ui.single,
        isA<UpdateComponentsMessage>(),
      );
    });

    test('parses a streamed response', () async {
      final List<ResponsePart> parts = await processor()
          .parseStream(
            Stream<String>.fromIterable([
              '<a2ui-json>[{"version":"v0.9","deleteSurface":',
              '{"surfaceId":"s"}}]</a2ui-json>',
            ]),
          )
          .toList();

      expect(
        [
          for (final part in parts)
            if (part is A2uiPart) ...part.a2ui,
        ].single,
        isA<DeleteSurfaceMessage>(),
      );
    });

    test('exposes the active catalogs as an unmodifiable list', () {
      expect(
        () => processor().activeCatalogs.add(MinimalCatalog()),
        throwsUnsupportedError,
      );
    });
  });
}
