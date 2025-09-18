// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fcp_client/fcp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FcpView Error Handling', () {
    testWidgets('displays error for cyclical layout', (tester) async {
      final packet = DynamicUIPacket.fromMap({
        'formatVersion': '1.0.0',
        'layout': {
          'root': 'node_a',
          'nodes': [
            {
              'id': 'node_a',
              'type': 'Container', // This type is not in the test catalog
              'properties': {'child': 'node_b'},
            },
            {
              'id': 'node_b',
              'type': 'Container',
              'properties': {'child': 'node_a'},
            },
          ],
        },
        'state': <String, Object?>{},
      });

      // We need a registry that has Container to test the cycle
      final cycleRegistry = WidgetCatalogRegistry()
        ..register(
          CatalogItem(
            name: 'Container',
            builder: (context, node, properties, children) =>
                Container(child: children['child']?.first),
            definition: WidgetDefinition.fromMap({
              'properties': {
                'child': {'type': 'WidgetId'},
              },
            }),
          ),
        );
      final cycleCatalog = cycleRegistry.buildCatalog(catalogVersion: '1.0.0');

      await tester.pumpWidget(
        MaterialApp(
          home: FcpView(
            packet: packet,
            registry: cycleRegistry,
            catalog: cycleCatalog,
          ),
        ),
      );

      expect(find.textContaining('Cyclical layout detected'), findsOneWidget);
    });
  });
}
