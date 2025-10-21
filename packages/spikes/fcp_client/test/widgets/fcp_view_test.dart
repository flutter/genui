// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fcp_client/fcp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

void main() {
  group('FcpView', () {
    testWidgets('renders a simple static UI', (WidgetTester tester) async {
      final registry = WidgetCatalogRegistry()
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
          'root': 'hello',
          'nodes': [
            {
              'id': 'hello',
              'type': 'Text',
              'properties': {'data': 'Hello, FCP!'},
            },
          ],
        },
        'state': <String, Object?>{},
      });

      await tester.pumpWidget(
        MaterialApp(
          home: FcpView(packet: packet, catalog: catalog, registry: registry),
        ),
      );

      expect(find.text('Hello, FCP!'), findsOneWidget);
    });

    testWidgets('renders a nested UI', (WidgetTester tester) async {
      final registry = WidgetCatalogRegistry()
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
        )
        ..register(
          CatalogItem(
            name: 'Column',
            builder: (context, node, properties, children) {
              return Column(children: children['children'] ?? []);
            },
            definition: WidgetDefinition.fromMap({
              'properties': {
                'children': {'type': 'ListOfWidgetIds'},
              },
            }),
          ),
        );

      final catalog = registry.buildCatalog(catalogVersion: '1.0.0');

      final packet = DynamicUIPacket.fromMap({
        'formatVersion': '1.0.0',
        'layout': {
          'root': 'col',
          'nodes': [
            {
              'id': 'col',
              'type': 'Column',
              'properties': {
                'children': ['text1', 'text2'],
              },
            },
            {
              'id': 'text1',
              'type': 'Text',
              'properties': {'data': 'Line 1'},
            },
            {
              'id': 'text2',
              'type': 'Text',
              'properties': {'data': 'Line 2'},
            },
          ],
        },
        'state': <String, Object?>{},
      });

      await tester.pumpWidget(
        MaterialApp(
          home: FcpView(packet: packet, catalog: catalog, registry: registry),
        ),
      );

      expect(find.text('Line 1'), findsOneWidget);
      expect(find.text('Line 2'), findsOneWidget);
    });

    testWidgets('displays an error for an unknown widget type', (
      WidgetTester tester,
    ) async {
      final registry = WidgetCatalogRegistry();
      final catalog = registry.buildCatalog(catalogVersion: '1.0.0');
      final packet = DynamicUIPacket.fromMap({
        'formatVersion': '1.0.0',
        'layout': {
          'root': 'unknown',
          'nodes': [
            {'id': 'unknown', 'type': 'MyBogusWidget'},
          ],
        },
        'state': <String, Object?>{},
      });

      await tester.pumpWidget(
        MaterialApp(
          home: FcpView(packet: packet, catalog: catalog, registry: registry),
        ),
      );

      expect(find.textContaining('No builder registered'), findsOneWidget);
    });

    testWidgets('rebuilds when a new packet is provided', (
      WidgetTester tester,
    ) async {
      final registry = WidgetCatalogRegistry()
        ..register(
          CatalogItem(
            name: 'Text',
            builder: (context, node, properties, children) {
              return Text(
                properties['data'] as String? ?? '',
                textDirection: TextDirection.ltr,
              );
            },
            definition: WidgetDefinition(
              properties: ObjectSchema(properties: {'data': Schema.string()}),
              events: ObjectSchema(
                properties: {
                  'onChanged': Schema.object(
                    properties: {'data': Schema.boolean()},
                  ),
                },
              ),
            ),
          ),
        );
      final catalog = registry.buildCatalog(catalogVersion: '1.0.0');

      final initialPacket = DynamicUIPacket.fromMap({
        'formatVersion': '1.0.0',
        'layout': {
          'root': 'text',
          'nodes': [
            {
              'id': 'text',
              'type': 'Text',
              'properties': {'data': 'Initial'},
            },
          ],
        },
        'state': <String, Object?>{},
      });

      final newPacket = DynamicUIPacket.fromMap({
        'formatVersion': '1.0.0',
        'layout': {
          'root': 'text',
          'nodes': [
            {
              'id': 'text',
              'type': 'Text',
              'properties': {'data': 'Updated'},
            },
          ],
        },
        'state': <String, Object?>{},
      });

      await tester.pumpWidget(
        MaterialApp(
          home: FcpView(
            packet: initialPacket,
            catalog: catalog,
            registry: registry,
          ),
        ),
      );
      expect(find.text('Initial'), findsOneWidget);
      expect(find.text('Updated'), findsNothing);

      await tester.pumpWidget(
        MaterialApp(
          home: FcpView(
            packet: newPacket,
            catalog: catalog,
            registry: registry,
          ),
        ),
      );
      expect(find.text('Initial'), findsNothing);
      expect(find.text('Updated'), findsOneWidget);
    });
  });

  group('FcpView State and Bindings', () {
    testWidgets('renders UI with bound state', (WidgetTester tester) async {
      final registry = WidgetCatalogRegistry()
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
          'root': 'text',
          'nodes': [
            {
              'id': 'text',
              'type': 'Text',
              'bindings': {
                'data': {'path': 'message'},
              },
            },
          ],
        },
        'state': <String, Object?>{'message': 'Hello from state!'},
      });

      await tester.pumpWidget(
        MaterialApp(
          home: FcpView(packet: packet, catalog: catalog, registry: registry),
        ),
      );

      expect(find.text('Hello from state!'), findsOneWidget);
    });

    testWidgets('UI updates when state changes via controller', (
      WidgetTester tester,
    ) async {
      final registry = WidgetCatalogRegistry()
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
      final controller = FcpViewController();

      final packet = DynamicUIPacket.fromMap({
        'formatVersion': '1.0.0',
        'layout': {
          'root': 'text',
          'nodes': [
            {
              'id': 'text',
              'type': 'Text',
              'bindings': {
                'data': {'path': 'message'},
              },
            },
          ],
        },
        'state': <String, Object?>{'message': 'Initial'},
      });

      await tester.pumpWidget(
        MaterialApp(
          home: FcpView(
            packet: packet,
            catalog: catalog,
            registry: registry,
            controller: controller,
          ),
        ),
      );

      expect(find.text('Initial'), findsOneWidget);

      // Act
      controller.patchState(
        StateUpdate.fromMap({
          'patches': [
            {'op': 'replace', 'path': '/message', 'value': 'Updated'},
          ],
        }),
      );
      await tester.pump();

      // Assert
      expect(find.text('Initial'), findsNothing);
      expect(find.text('Updated'), findsOneWidget);
    });
  });

  group('FcpView Events', () {
    testWidgets('fires onEvent callback with correct payload', (
      WidgetTester tester,
    ) async {
      EventPayload? capturedPayload;

      final registry = WidgetCatalogRegistry()
        ..register(
          CatalogItem(
            name: 'EventButton',
            builder: (context, node, properties, children) {
              return ElevatedButton(
                onPressed: () {
                  FcpProvider.of(context)?.onEvent?.call(
                    EventPayload.fromMap({
                      'sourceNodeId': node.id,
                      'eventName': 'onPressed',
                      'arguments': <String, Object?>{'test': 'data'},
                    }),
                  );
                },
                child: const Text('Tap Me'),
              );
            },
            definition: WidgetDefinition.fromMap({
              'properties': <String, Object?>{},
              'events': {
                'onPressed': {
                  'type': 'object',
                  'properties': {
                    'test': {'type': 'String'},
                  },
                },
              },
            }),
          ),
        );
      final catalog = registry.buildCatalog(catalogVersion: '1.0.0');

      final packet = DynamicUIPacket.fromMap({
        'formatVersion': '1.0.0',
        'layout': {
          'root': 'button',
          'nodes': [
            {'id': 'button', 'type': 'EventButton'},
          ],
        },
        'state': <String, Object?>{},
      });

      await tester.pumpWidget(
        MaterialApp(
          home: FcpView(
            packet: packet,
            catalog: catalog,
            registry: registry,
            onEvent: (payload) {
              capturedPayload = payload;
            },
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(capturedPayload, isNotNull);
      expect(capturedPayload!.sourceNodeId, 'button');
      expect(capturedPayload!.eventName, 'onPressed');
      expect(capturedPayload!.arguments, {'test': 'data'});
    });
  });

  group('FcpView Layout Updates', () {
    testWidgets('adds a widget with LayoutUpdate', (WidgetTester tester) async {
      final controller = FcpViewController();
      final registry = WidgetCatalogRegistry()
        ..register(
          CatalogItem(
            name: 'Column',
            builder: (context, node, properties, children) {
              return Column(children: children['children'] ?? []);
            },
            definition: WidgetDefinition.fromMap({
              'properties': {
                'children': {'type': 'ListOfWidgetIds'},
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
          'root': 'col',
          'nodes': [
            {
              'id': 'col',
              'type': 'Column',
              'properties': {
                'children': ['text1'],
              },
            },
            {
              'id': 'text1',
              'type': 'Text',
              'properties': {'data': 'First'},
            },
          ],
        },
        'state': <String, Object?>{},
      });

      await tester.pumpWidget(
        MaterialApp(
          home: FcpView(
            packet: packet,
            catalog: catalog,
            registry: registry,
            controller: controller,
          ),
        ),
      );

      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsNothing);

      // Act
      controller.patchLayout(
        LayoutUpdate.fromMap({
          'operations': [
            {
              'op': 'add',
              'nodes': [
                {
                  'id': 'text2',
                  'type': 'Text',
                  'properties': {'data': 'Second'},
                },
              ],
            },
            {
              'op': 'replace',
              'nodes': [
                {
                  'id': 'col',
                  'type': 'Column',
                  'properties': {
                    'children': ['text1', 'text2'],
                  },
                },
              ],
            },
          ],
        }),
      );
      await tester.pump();

      // Assert
      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
    });

    testWidgets('removes a widget with LayoutUpdate', (
      WidgetTester tester,
    ) async {
      final controller = FcpViewController();
      final registry = WidgetCatalogRegistry()
        ..register(
          CatalogItem(
            name: 'Column',
            builder: (context, node, properties, children) {
              return Column(children: children['children'] ?? []);
            },
            definition: WidgetDefinition.fromMap({
              'properties': {
                'children': {'type': 'ListOfWidgetIds'},
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
          'root': 'col',
          'nodes': [
            {
              'id': 'col',
              'type': 'Column',
              'properties': {
                'children': ['text1', 'text2'],
              },
            },
            {
              'id': 'text1',
              'type': 'Text',
              'properties': {'data': 'First'},
            },
            {
              'id': 'text2',
              'type': 'Text',
              'properties': {'data': 'Second'},
            },
          ],
        },
        'state': <String, Object?>{},
      });

      await tester.pumpWidget(
        MaterialApp(
          home: FcpView(
            packet: packet,
            catalog: catalog,
            registry: registry,
            controller: controller,
          ),
        ),
      );

      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);

      // Act
      controller.patchLayout(
        LayoutUpdate.fromMap({
          'operations': [
            {
              'op': 'remove',
              'nodeIds': ['text2'],
            },
            {
              'op': 'replace',
              'nodes': [
                {
                  'id': 'col',
                  'type': 'Column',
                  'properties': {
                    'children': ['text1'],
                  },
                },
              ],
            },
          ],
        }),
      );
      await tester.pump();

      // Assert
      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsNothing);
    });

    testWidgets('updates a widget with LayoutUpdate', (
      WidgetTester tester,
    ) async {
      final controller = FcpViewController();
      final registry = WidgetCatalogRegistry()
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
          'root': 'text1',
          'nodes': [
            {
              'id': 'text1',
              'type': 'Text',
              'properties': {'data': 'Before'},
            },
          ],
        },
        'state': <String, Object?>{},
      });

      await tester.pumpWidget(
        MaterialApp(
          home: FcpView(
            packet: packet,
            catalog: catalog,
            registry: registry,
            controller: controller,
          ),
        ),
      );

      expect(find.text('Before'), findsOneWidget);
      expect(find.text('After'), findsNothing);

      // Act
      controller.patchLayout(
        LayoutUpdate.fromMap({
          'operations': [
            {
              'op': 'replace',
              'nodes': [
                {
                  'id': 'text1',
                  'type': 'Text',
                  'properties': {'data': 'After'},
                },
              ],
            },
          ],
        }),
      );
      await tester.pump();

      // Assert
      expect(find.text('Before'), findsNothing);
      expect(find.text('After'), findsOneWidget);
    });
  });
}
