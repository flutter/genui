// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_agent/a2ui_agent.dart';
import 'package:a2ui_core/a2ui_core.dart';
import 'package:test/test.dart';

void main() {
  final validator = A2uiPayloadValidator(catalogs: [MinimalCatalog()]);
  final String minimalId = MinimalCatalog().id;

  UpdateComponentsMessage components(List<Map<String, dynamic>> components) =>
      UpdateComponentsMessage(surfaceId: 's', components: components);

  List<String> issues(
    List<AgentToRendererMessage> messages, {
    bool partial = false,
    bool checkReferences = false,
  }) => validator
      .validate(messages, partial: partial, checkReferences: checkReferences)
      .map((issue) => issue.toString())
      .toList();

  group('catalog conformance', () {
    test('accepts a conforming payload', () {
      expect(
        issues([
          CreateSurfaceMessage(surfaceId: 's', catalogId: minimalId),
          components([
            {
              'id': 'root',
              'component': 'Column',
              'children': ['a'],
            },
            {'id': 'a', 'component': 'Text', 'text': 'Hi', 'variant': 'h1'},
          ]),
        ]),
        isEmpty,
      );
    });

    test('flags an unknown component', () {
      expect(
        issues([
          components([
            {'id': 'a', 'component': 'Carousel'},
          ]),
        ]),
        [contains("Unknown component 'Carousel'")],
      );
    });

    test('flags a missing required property', () {
      expect(
        issues([
          components([
            {'id': 'a', 'component': 'Text'},
          ]),
        ]),
        [contains("missing required property 'text'")],
      );
    });

    test('flags a property the component does not declare', () {
      expect(
        issues([
          components([
            {'id': 'a', 'component': 'Text', 'text': 'Hi', 'colour': 'red'},
          ]),
        ]),
        [contains("has no property 'colour'")],
      );
    });

    test('flags a surface bound to an inactive catalog', () {
      expect(
        issues([CreateSurfaceMessage(surfaceId: 's', catalogId: 'other')]),
        [contains('not active for this session')],
      );
    });

    test('flags a duplicate component id in one message', () {
      expect(
        issues([
          components([
            {'id': 'a', 'component': 'Text', 'text': '1'},
            {'id': 'a', 'component': 'Text', 'text': '2'},
          ]),
        ]),
        [contains('Duplicate component id')],
      );
    });

    test('flags a component with no id', () {
      expect(
        issues([
          components([
            {'component': 'Text', 'text': 'Hi'},
          ]),
        ]),
        [contains("missing a string 'id'")],
      );
    });

    test('flags a version the session did not negotiate', () {
      expect(issues([DeleteSurfaceMessage(version: 'v0.8', surfaceId: 's')]), [
        contains('negotiated v0.9'),
      ]);
    });
  });

  group('partial payloads', () {
    test('skips required-property checks while streaming', () {
      expect(
        issues([
          components([
            {'id': 'a', 'component': 'Text'},
          ]),
        ], partial: true),
        isEmpty,
      );
    });

    test('still flags an unknown component while streaming', () {
      expect(
        issues([
          components([
            {'id': 'a', 'component': 'Carousel'},
          ]),
        ], partial: true),
        [contains('Unknown component')],
      );
    });
  });

  group('references', () {
    test('flags a child that is never defined', () {
      expect(
        issues([
          components([
            {
              'id': 'root',
              'component': 'Column',
              'children': ['missing'],
            },
          ]),
        ], checkReferences: true),
        [contains("references undefined component 'missing'")],
      );
    });

    test('flags a reference cycle', () {
      expect(
        issues([
          components([
            {
              'id': 'root',
              'component': 'Column',
              'children': ['child'],
            },
            {
              'id': 'child',
              'component': 'Column',
              'children': ['root'],
            },
          ]),
        ], checkReferences: true),
        [contains('reference cycle')],
      );
    });

    test('follows a list template reference', () {
      expect(
        issues([
          components([
            {
              'id': 'root',
              'component': 'Column',
              'children': {'componentId': 'missing', 'path': '/items'},
            },
          ]),
        ], checkReferences: true),
        [contains("references undefined component 'missing'")],
      );
    });

    test('does not check references by default', () {
      expect(
        issues([
          components([
            {
              'id': 'root',
              'component': 'Column',
              'children': ['defined-elsewhere'],
            },
          ]),
        ]),
        isEmpty,
      );
    });
  });

  group('JSON pointers', () {
    test('accepts well-formed pointers', () {
      expect(isValidJsonPointer('/a/b'), isTrue);
      expect(isValidJsonPointer(''), isTrue);
      expect(isValidJsonPointer('/a~0b/c~1d'), isTrue);
      expect(isValidJsonPointer('relative'), isTrue);
    });

    test('rejects a malformed escape', () {
      expect(isValidJsonPointer('/a~2b'), isFalse);
      expect(isValidJsonPointer('/a~'), isFalse);
    });

    test('flags a malformed data model path', () {
      expect(
        issues([
          UpdateDataModelMessage(surfaceId: 's', path: '/bad~2path', value: 1),
        ]),
        [contains('not a valid JSON Pointer')],
      );
    });

    test('flags a malformed data binding', () {
      expect(
        issues([
          components([
            {
              'id': 'a',
              'component': 'Text',
              'text': {'path': '/bad~9'},
            },
          ]),
        ]),
        [contains('invalid JSON Pointer')],
      );
    });
  });

  group('validateOrThrow', () {
    test('throws with every issue listed', () {
      expect(
        () => validator.validateOrThrow([
          components([
            {'id': 'a', 'component': 'Carousel'},
            {'id': 'b', 'component': 'Text'},
          ]),
        ]),
        throwsA(
          isA<A2uiValidationError>().having(
            (error) => error.message,
            'message',
            allOf(contains('Carousel'), contains("required property 'text'")),
          ),
        ),
      );
    });

    test('does not throw for a conforming payload', () {
      expect(
        () => validator.validateOrThrow([
          components([
            {'id': 'a', 'component': 'Text', 'text': 'Hi'},
          ]),
        ]),
        returnsNormally,
      );
    });
  });

  group('without catalogs', () {
    test('still runs structural checks', () {
      const bare = A2uiPayloadValidator(catalogs: []);

      expect(
        bare.validate([
          UpdateComponentsMessage(
            surfaceId: 's',
            components: [
              {'id': 'a', 'component': 'AnythingGoes'},
            ],
          ),
        ]),
        isEmpty,
      );
      expect(
        bare.validate([DeleteSurfaceMessage(surfaceId: '')]),
        hasLength(1),
      );
    });
  });
}
