// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fcp_client/fcp_client.dart';
import 'package:fcp_tools/fcp_tools.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FcpSurfaceManager', () {
    late FcpSurfaceManager manager;

    setUp(() {
      manager = FcpSurfaceManager();
    });

    test('setSurface adds a new surface', () {
      final packet = DynamicUIPacket(
        layout: Layout(root: 'root', nodes: []),
        state: {},
      );
      manager.setSurface('test', packet);
      expect(manager.getController('test'), isNotNull);
      expect(manager.getPacket('test'), packet);
    });

    test('setSurface replaces an existing surface', () {
      final packet1 = DynamicUIPacket(
        layout: Layout(root: 'root', nodes: []),
        state: {},
      );
      manager.setSurface('test', packet1);
      final controller1 = manager.getController('test');

      final packet2 = DynamicUIPacket(
        layout: Layout(root: 'root2', nodes: []),
        state: {},
      );
      manager.setSurface('test', packet2);
      final controller2 = manager.getController('test');

      expect(controller1, same(controller2));
      expect(manager.getPacket('test'), packet2);
    });

    test('getController returns null for non-existent surface', () {
      expect(manager.getController('test'), isNull);
    });

    test('getPacket returns null for non-existent surface', () {
      expect(manager.getPacket('test'), isNull);
    });

    test('listSurfaces returns correct list of IDs', () {
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
      expect(manager.listSurfaces(), ['test1', 'test2']);
    });

    test('removeSurface removes a surface', () {
      manager.setSurface(
        'test',
        DynamicUIPacket(
          layout: Layout(root: 'root', nodes: []),
          state: {},
        ),
      );
      manager.removeSurface('test');
      expect(manager.getController('test'), isNull);
      expect(manager.getPacket('test'), isNull);
    });

    test('dispose disposes all controllers', () {
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
      manager.dispose();
      expect(manager.listSurfaces(), isEmpty);
    });
  });
}
