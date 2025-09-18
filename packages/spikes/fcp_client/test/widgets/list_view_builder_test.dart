// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fcp_client/fcp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ListViewBuilder', () {
    testWidgets('builds a list of items from state', (
      WidgetTester tester,
    ) async {
      final registry = WidgetCatalogRegistry()
        ..register(
          CatalogItem(
            name: 'ListViewBuilder',
            builder: (context, node, properties, children) =>
                const SizedBox.shrink(),
            definition: WidgetDefinition.fromMap({
              'properties': {},
              'bindings': {
                'data': {'path': 'string'},
              },
            }),
          ),
        )
        ..register(
          CatalogItem(
            name: 'Text',
            builder: (context, node, properties, children) {
              return Text(
                properties['data'] as String? ?? '',
                textDirection: TextDirection.ltr,
              );
            },
            definition: WidgetDefinition.fromMap({
              'properties': {
                'data': {'type': 'String'},
              },
            }),
          ),
        );
      final catalog = registry.buildCatalog(catalogVersion: '1.0.0');

      final packet = DynamicUIPacket.fromMap({
        'formatVersion': '1.0.0',
        'layout': {
          'root': 'my_list',
          'nodes': [
            {
              'id': 'my_list',
              'type': 'ListViewBuilder',
              'bindings': {
                'data': {'path': 'items'},
              },
              'itemTemplate': {
                'id': 'item_template',
                'type': 'Text',
                'bindings': {
                  'data': {'path': 'item.name'},
                },
              },
            },
          ],
        },
        'state': {
          'items': [
            {'name': 'Apple'},
            {'name': 'Banana'},
            {'name': 'Cherry'},
          ],
        },
      });

      await tester.pumpWidget(
        MaterialApp(
          home: FcpView(packet: packet, catalog: catalog, registry: registry),
        ),
      );

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Cherry'), findsOneWidget);
    });

    testWidgets('itemTemplate bindings are resolved correctly', (
      WidgetTester tester,
    ) async {
      final registry = WidgetCatalogRegistry()
        ..register(
          CatalogItem(
            name: 'ListViewBuilder',
            builder: (context, node, properties, children) =>
                const SizedBox.shrink(),
            definition: WidgetDefinition.fromMap({
              'properties': {},
              'bindings': {
                'data': {'path': 'string'},
              },
            }),
          ),
        )
        ..register(
          CatalogItem(
            name: 'Text',
            builder: (context, node, properties, children) {
              return Text(
                properties['data'] as String? ?? '',
                textDirection: TextDirection.ltr,
              );
            },
            definition: WidgetDefinition.fromMap({
              'properties': {
                'data': {'type': 'String'},
              },
            }),
          ),
        );
      final catalog = registry.buildCatalog(catalogVersion: '1.0.0');

      final packet = DynamicUIPacket.fromMap({
        'formatVersion': '1.0.0',
        'layout': {
          'root': 'my_list',
          'nodes': [
            {
              'id': 'my_list',
              'type': 'ListViewBuilder',
              'bindings': {
                'data': {'path': 'items'},
              },
              'itemTemplate': {
                'id': 'item_template',
                'type': 'Text',
                'bindings': {
                  'data': {'path': 'item.name', 'format': 'Fruit: {}'},
                },
              },
            },
          ],
        },
        'state': {
          'items': [
            {'name': 'Apple'},
          ],
        },
      });

      await tester.pumpWidget(
        MaterialApp(
          home: FcpView(packet: packet, catalog: catalog, registry: registry),
        ),
      );

      expect(find.text('Fruit: Apple'), findsOneWidget);
    });
  });
}
