// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fcp_client/fcp_client.dart';
import 'package:fcp_tools/fcp_tools.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mock_fcp_view_controller.dart';

void main() {
  group('ManageUiTool', () {
    late FcpSurfaceManager manager;
    late ManageUiTool tool;

    setUp(() {
      manager = FcpSurfaceManager();
      tool = ManageUiTool(manager);
    });

    test('set creates a new surface', () async {
      final result = await tool.set.invoke({
        'surfaceId': 'test',
        'layout': <String, Object?>{'root': 'root', 'nodes': []},
        'state': <String, Object?>{},
      });
      expect(result['success'], true);
      expect(manager.getController('test'), isNotNull);
      expect(manager.getPacket('test'), isNotNull);
    });

    test('set updates an existing surface', () async {
      await tool.set.invoke({
        'surfaceId': 'test',
        'layout': <String, Object?>{'root': 'root', 'nodes': []},
        'state': <String, Object?>{'key': 'value1'},
      });
      final packet1 = manager.getPacket('test');
      expect(packet1!.state['key'], 'value1');

      await tool.set.invoke({
        'surfaceId': 'test',
        'layout': <String, Object?>{'root': 'root2', 'nodes': []},
        'state': <String, Object?>{'key': 'value2'},
      });
      final packet2 = manager.getPacket('test');
      expect(packet2!.state['key'], 'value2');
      expect(packet2.layout.root, 'root2');
    });

    test('get returns the correct data', () async {
      final layout = Layout(root: 'root', nodes: []);
      final state = {'key': 'value'};
      final packet = DynamicUIPacket(layout: layout, state: state);
      manager.setSurface('test', packet);

      final result = await tool.get.invoke({'surfaceId': 'test'});
      expect(result['layout'], layout.toJson());
      expect(result['state'], state);
    });

    test('get returns empty data for non-existent surface', () async {
      final result = await tool.get.invoke({'surfaceId': 'test'});
      expect(result['layout'], <String, Object?>{});
      expect(result['state'], <String, Object?>{});
    });

    test('list returns the correct data', () async {
      manager.setSurface(
        'test1',
        DynamicUIPacket(
          layout: Layout(root: 'root', nodes: []),
          state: {},
        ),
      );
      manager.setSurface(
        'test2',
        DynamicUIPacket(
          layout: Layout(root: 'root', nodes: []),
          state: {},
        ),
      );
      final result = await tool.list.invoke({});
      expect(result['surfaceIds'], ['test1', 'test2']);
    });

    test('remove removes a surface', () async {
      manager.setSurface(
        'test',
        DynamicUIPacket(
          layout: Layout(root: 'root', nodes: []),
          state: {},
        ),
      );
      final result = await tool.remove.invoke({'surfaceId': 'test'});
      expect(result['success'], true);
      expect(manager.getController('test'), isNull);
    });

    test('patchLayout calls the controller', () async {
      final mockController = MockFcpViewController();
      manager.controllers['test'] = mockController;
      final operations = [
        {
          'op': 'add',
          'path': '/nodes/-',
          'value': {'id': 'new', 'type': 'Text'},
        },
      ];
      await tool.patchLayout.invoke({
        'surfaceId': 'test',
        'operations': operations,
      });
      expect(mockController.patchLayoutCallCount, 1);
      expect(mockController.lastLayoutUpdate!.operations.first.op, 'add');
    });

    test('patchState calls the controller', () async {
      final mockController = MockFcpViewController();
      manager.controllers['test'] = mockController;
      final patches = [
        {'op': 'replace', 'path': '/key', 'value': 'newValue'},
      ];
      await tool.patchState.invoke({'surfaceId': 'test', 'patches': patches});
      expect(mockController.patchStateCallCount, 1);
      expect(mockController.lastStateUpdate!.patches.first['op'], 'replace');
    });
  });
}
