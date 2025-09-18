// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fcp_client/src/core/layout_patcher.dart';
import 'package:fcp_client/src/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LayoutPatcher', () {
    late LayoutPatcher patcher;
    late Map<String, LayoutNode> nodeMap;

    setUp(() {
      patcher = LayoutPatcher();
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
        'operations': [
          {
            'op': 'add',
            'nodes': [
              {'id': 'child3', 'type': 'Button'},
            ],
          },
        ],
      });

      patcher.apply(nodeMap, add);

      expect(nodeMap.containsKey('child3'), isTrue);
      expect(nodeMap['child3']!.type, 'Button');
    });

    test('handles "remove" operation', () {
      final remove = LayoutUpdate.fromMap({
        'operations': [
          {
            'op': 'remove',
            'nodeIds': ['child1', 'child2'],
          },
        ],
      });

      patcher.apply(nodeMap, remove);

      expect(nodeMap.containsKey('child1'), isFalse);
      expect(nodeMap.containsKey('child2'), isFalse);
      expect(nodeMap.containsKey('root'), isTrue);
    });

    test('handles "replace" operation', () {
      final replace = LayoutUpdate.fromMap({
        'operations': [
          {
            'op': 'replace',
            'nodes': [
              {
                'id': 'child1',
                'type': 'Text',
                'properties': {'text': 'Goodbye'},
              },
            ],
          },
        ],
      });

      patcher.apply(nodeMap, replace);

      expect(nodeMap['child1']!.properties!['text'], 'Goodbye');
    });

    test('handles multiple operations in sequence', () {
      final update = LayoutUpdate.fromMap({
        'operations': [
          {
            'op': 'remove',
            'nodeIds': ['child2'],
          },
          {
            'op': 'replace',
            'nodes': [
              {
                'id': 'child1',
                'type': 'Text',
                'properties': {'text': 'Updated'},
              },
            ],
          },
          {
            'op': 'add',
            'nodes': [
              {'id': 'new_child', 'type': 'Icon'},
            ],
          },
        ],
      });

      patcher.apply(nodeMap, update);

      expect(nodeMap.containsKey('child2'), isFalse);
      expect(nodeMap['child1']!.properties!['text'], 'Updated');
      expect(nodeMap.containsKey('new_child'), isTrue);
    });

    test('ignores unknown operations gracefully', () {
      final update = LayoutUpdate.fromMap({
        'operations': [
          {'op': 'unknown_op'},
        ],
      });

      // Should not throw
      patcher.apply(nodeMap, update);
      expect(nodeMap.length, 3);
    });

    test('does not fail on empty or null node/id lists', () {
      final update = LayoutUpdate.fromMap({
        'operations': [
          {'op': 'add', 'nodes': <Map<String, Object?>>[]},
          {'op': 'remove', 'nodeIds': null},
          {'op': 'replace', 'nodes': null},
        ],
      });

      // Should not throw
      patcher.apply(nodeMap, update);
      expect(nodeMap.length, 3);
    });
    test('does not throw when updating a non-existent node', () {
      final replace = LayoutUpdate.fromMap({
        'operations': [
          {
            'op': 'replace',
            'nodes': [
              {'id': 'non_existent', 'type': 'Text'},
            ],
          },
        ],
      });

      // Should not throw and should not add the node
      patcher.apply(nodeMap, replace);
      expect(nodeMap.containsKey('non_existent'), isFalse);
      expect(nodeMap.length, 3);
    });
  });
}
