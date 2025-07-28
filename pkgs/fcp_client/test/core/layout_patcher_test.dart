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
        'root': LayoutNode.fromJson({
          'id': 'root',
          'type': 'Container',
          'properties': {'child': 'child1'},
        }),
        'child1': LayoutNode.fromJson({
          'id': 'child1',
          'type': 'Text',
          'properties': {'text': 'Hello'},
        }),
        'child2': LayoutNode.fromJson({
          'id': 'child2',
          'type': 'Text',
          'properties': {'text': 'World'},
        }),
      };
    });

    test('handles "add" operation', () {
      final update = LayoutUpdate({
        'operations': [
          {
            'op': 'add',
            'nodes': [
              {'id': 'child3', 'type': 'Button'},
            ],
          },
        ],
      });

      patcher.apply(nodeMap, update);

      expect(nodeMap.containsKey('child3'), isTrue);
      expect(nodeMap['child3']!.type, 'Button');
    });

    test('handles "remove" operation', () {
      final update = LayoutUpdate({
        'operations': [
          {
            'op': 'remove',
            'nodeIds': ['child1', 'child2'],
          },
        ],
      });

      patcher.apply(nodeMap, update);

      expect(nodeMap.containsKey('child1'), isFalse);
      expect(nodeMap.containsKey('child2'), isFalse);
      expect(nodeMap.containsKey('root'), isTrue);
    });

    test('handles "update" operation', () {
      final update = LayoutUpdate({
        'operations': [
          {
            'op': 'update',
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

      patcher.apply(nodeMap, update);

      expect(nodeMap['child1']!.properties!['text'], 'Goodbye');
    });

    test('handles multiple operations in sequence', () {
      final update = LayoutUpdate({
        'operations': [
          {
            'op': 'remove',
            'nodeIds': ['child2'],
          },
          {
            'op': 'update',
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
      final update = LayoutUpdate({
        'operations': [
          {'op': 'unknown_op'},
        ],
      });

      // Should not throw
      patcher.apply(nodeMap, update);
      expect(nodeMap.length, 3);
    });

    test('does not fail on empty or null node/id lists', () {
      final update = LayoutUpdate({
        'operations': [
          {'op': 'add', 'nodes': <Map<String, Object?>>[]},
          {'op': 'remove', 'nodeIds': null},
          {'op': 'update', 'nodes': null},
        ],
      });

      // Should not throw
      patcher.apply(nodeMap, update);
      expect(nodeMap.length, 3);
    });
    test('does not throw when updating a non-existent node', () {
      final update = LayoutUpdate({
        'operations': [
          {
            'op': 'update',
            'nodes': [
              {'id': 'non_existent', 'type': 'Text'},
            ],
          },
        ],
      });

      // Should not throw and should not add the node
      patcher.apply(nodeMap, update);
      expect(nodeMap.containsKey('non_existent'), isFalse);
      expect(nodeMap.length, 3);
    });
  });
}
