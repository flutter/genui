// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fcp_client/src/core/layout_patcher.dart';
import 'package:fcp_client/src/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_patch/json_patch.dart';

void main() {
  group('LayoutPatcher', () {
    late LayoutPatcher patcher;
    late Map<String, LayoutNode> nodeMap;

    setUp(() {
      patcher = const LayoutPatcher();
      nodeMap = {
        'root': LayoutNode.fromMap({
          'id': 'root',
          'type': 'Container',
          'properties': {'child': 'child1'},
        }),
        'child1': LayoutNode.fromMap({
          'id': 'child1',
          'type': 'Text',
          'properties': {'text': 'Hello'},
        }),
        'child2': LayoutNode.fromMap({
          'id': 'child2',
          'type': 'Text',
          'properties': {'text': 'World'},
        }),
      };
    });

    test('handles "add" operation', () {
      final add = LayoutUpdate.fromMap({
        'patches': [
          {
            'op': 'add',
            'path': '/nodes/child3',
            'value': {'id': 'child3', 'type': 'Button'},
          },
        ],
      });

      patcher.apply(nodeMap, add);

      expect(nodeMap.containsKey('child3'), isTrue);
      expect(nodeMap['child3']!.type, 'Button');
    });

    test('handles "remove" operation', () {
      final remove = LayoutUpdate.fromMap({
        'patches': [
          {'op': 'remove', 'path': '/nodes/child1'},
          {'op': 'remove', 'path': '/nodes/child2'},
        ],
      });

      patcher.apply(nodeMap, remove);

      expect(nodeMap.containsKey('child1'), isFalse);
      expect(nodeMap.containsKey('child2'), isFalse);
      expect(nodeMap.containsKey('root'), isTrue);
    });

    test('handles "replace" operation', () {
      final replace = LayoutUpdate.fromMap({
        'patches': [
          {
            'op': 'replace',
            'path': '/nodes/child1/properties/text',
            'value': 'Goodbye',
          },
        ],
      });

      patcher.apply(nodeMap, replace);

      expect(nodeMap['child1']!.properties!['text'], 'Goodbye');
    });

    test('handles multiple operations in sequence', () {
      final update = LayoutUpdate.fromMap({
        'patches': [
          {'op': 'remove', 'path': '/nodes/child2'},
          {
            'op': 'replace',
            'path': '/nodes/child1/properties/text',
            'value': 'Updated',
          },
          {
            'op': 'add',
            'path': '/nodes/new_child',
            'value': {'id': 'new_child', 'type': 'Icon'},
          },
        ],
      });

      patcher.apply(nodeMap, update);

      expect(nodeMap.containsKey('child2'), isFalse);
      expect(nodeMap['child1']!.properties!['text'], 'Updated');
      expect(nodeMap.containsKey('new_child'), isTrue);
    });

    test('throws JsonPatchError for invalid path', () {
      final update = LayoutUpdate.fromMap({
        'patches': [
          {
            'op': 'replace',
            'path': '/nodes/child1/properties/nonexistent',
            'value': 'new',
          },
        ],
      });

      expect(
        () => patcher.apply(nodeMap, update),
        throwsA(isA<JsonPatchError>()),
      );
    });
  });
}
