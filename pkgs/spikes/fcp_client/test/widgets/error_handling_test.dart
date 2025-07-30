import 'package:fcp_client/fcp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final testRegistry = WidgetCatalogRegistry()
    ..register(
      CatalogItem(
        name: 'Text',
        builder: (context, node, properties, children) =>
            Text(properties['data'] as String? ?? ''),
        definition: WidgetDefinition({
          'properties': {
            'data': {'type': 'String', 'isRequired': true},
          },
        }),
      ),
    );

  final testCatalog = testRegistry.buildCatalog(
    catalogVersion: '1.0.0',
    dataTypes: <String, Object?>{},
  );

  group('FcpView Error Handling', () {
    testWidgets('displays error for cyclical layout', (tester) async {
      final packet = DynamicUIPacket({
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
                Container(child: children['child'] as Widget?),
            definition: WidgetDefinition({
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

    testWidgets('displays error for missing required property', (tester) async {
      final packet = DynamicUIPacket({
        'formatVersion': '1.0.0',
        'layout': {
          'root': 'text_node',
          'nodes': [
            {
              'id': 'text_node',
              'type': 'Text',
              'properties': <String, Object?>{}, // Missing 'data'
            },
          ],
        },
        'state': <String, Object?>{},
      });

      await tester.pumpWidget(
        MaterialApp(
          home: FcpView(
            packet: packet,
            registry: testRegistry,
            catalog: testCatalog,
          ),
        ),
      );

      expect(
        find.textContaining('Missing required property "data"'),
        findsOneWidget,
      );
    });
  });
}
