import 'package:fcp_client/fcp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final testRegistry = CatalogRegistry()
    ..register(
      'Container',
      (
        context,
        node,
        Map<String, Object?> properties,
        Map<String, dynamic> children,
      ) => Container(child: children['child'] as Widget?),
    )
    ..register(
      'Text',
      (
        context,
        node,
        Map<String, Object?> properties,
        Map<String, dynamic> children,
      ) => Text(properties['data'] as String? ?? ''),
    );

  final testCatalog = WidgetLibraryCatalog({
    'catalogVersion': '1.0.0',
    'dataTypes': <String, Object?>{},
    'items': <String, Object?>{
      'Text': {
        'properties': {
          'data': {'type': 'String', 'isRequired': true},
        },
      },
    },
  });

  DynamicUIPacket createPacket(Map<String, Object?> layout) {
    return DynamicUIPacket({
      'formatVersion': '1.0.0',
      'layout': layout,
      'state': <String, Object?>{},
    });
  }

  group('Error Handling', () {
    testWidgets('displays error for missing required property', (
      WidgetTester tester,
    ) async {
      final packet = createPacket({
        'root': 'root_text',
        'nodes': [
          {
            'id': 'root_text',
            'type': 'Text',
            'properties': <String, Object?>{}, // Missing 'data' property
          },
        ],
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
        find.text(
          'FCP Error: Missing required property "data" for catalog item type '
          '"Text".',
        ),
        findsOneWidget,
      );
    });
  });
}
