// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:fcp_client/fcp_client.dart';
import 'package:fcp_client/src/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

void main() {
  group('FCP Models', () {
    test('WidgetCatalog correctly parsed', () {
      final catalog = WidgetCatalog.fromMap(catalogJson);
      expect(catalog.catalogVersion, '1.0.0');
      expect(catalog.items, isA<Map>());
      expect(catalog.items.keys, contains('Text'));
    });

    test('WidgetDefinition correctly parsed', () {
      final items = catalogJson['items']! as Map<String, Object?>;
      final textItem = items['Text']! as Map<String, Object?>;
      final itemDef = WidgetDefinition.fromMap(textItem);
      expect(itemDef.properties, isA<ObjectSchema>());
      expect(itemDef.properties.value, contains('data'));
      expect(itemDef.events, isNull);
    });

    test('DynamicUIPacket correctly parsed', () {
      final packet = DynamicUIPacket.fromMap(packetJson);
      expect(packet.formatVersion, '1.0.0');
      expect(packet.layout, isA<Layout>());
      expect(packet.state, isA<Map>());
      expect(packet.state['title'], 'Hello, FCP!');
    });

    test('Layout correctly parsed', () {
      final layoutMap = packetJson['layout']! as Map<String, Object?>;
      final layout = Layout.fromMap(layoutMap);
      expect(layout.root, 'root_container');
      expect(layout.nodes, isA<List<LayoutNode>>());
      expect(layout.nodes.length, 3);
    });

    test('LayoutNode correctly parsed', () {
      final layoutMap = packetJson['layout']! as Map<String, Object?>;
      final nodes = layoutMap['nodes']! as List<Object?>;
      final firstNodeMap = nodes[0]! as Map<String, Object?>;
      final node = LayoutNode.fromMap(firstNodeMap);
      expect(node.id, 'root_container');
      expect(node.type, 'Container');
      expect(node.properties, isA<Map>());
      expect(node.properties!['child'], 'hello_text');
      expect(node.bindings, isNotNull);
      expect(node.itemTemplate, isNull);
    });

    test('LayoutNode correctly parsed with itemTemplate', () {
      final layoutMap = packetJson['layout']! as Map<String, Object?>;
      final nodes = layoutMap['nodes']! as List<Object?>;
      // Find the node with the itemTemplate for this test
      final listNodeMap =
          nodes.firstWhere(
                (n) => (n as Map<String, Object?>)['id'] == 'my_list_view',
              )
              as Map<String, Object?>;

      final node = LayoutNode.fromMap(listNodeMap);
      expect(node.id, 'my_list_view');
      expect(node.type, 'ListView');
      expect(node.itemTemplate, isNotNull);
      expect(node.itemTemplate, isA<LayoutNode>());
      expect(node.itemTemplate!.id, 'item_template');
      expect(node.itemTemplate!.type, 'Text');
    });

    test('WidgetDefinition correctly parsed with events', () {
      final items = catalogJson['items']! as Map<String, Object?>;
      final buttonItem = items['Button']! as Map<String, Object?>;
      final itemDef = WidgetDefinition.fromMap(buttonItem);
      expect(itemDef.events, isNotNull);
      expect(itemDef.events, isA<ObjectSchema>());
      expect(itemDef.events!.value.containsKey('onPressed'), isTrue);
    });

    test('EventPayload correctly parsed', () {
      final payload = EventPayload.fromMap({
        'sourceNodeId': 'my_button',
        'eventName': 'onPressed',
        'arguments': {'clickCount': 1},
      });
      expect(payload.sourceNodeId, 'my_button');
      expect(payload.eventName, 'onPressed');
      expect(payload.arguments, isA<Map>());
      expect(payload.arguments!['clickCount'], 1);
    });

    test('StateUpdate correctly parsed', () {
      final replace = StateUpdate.fromMap({
        'patches': [
          {'op': 'replace', 'path': '/title', 'value': 'New Title'},
        ],
      });
      expect(replace.patches, isA<List>());
      expect(replace.patches.first['op'], 'replace');
    });

    test('LayoutUpdate correctly parsed', () {
      final add = LayoutUpdate.fromMap({
        'operations': <Map<String, Object?>>[
          {'op': 'add', 'nodes': <Object?>[]},
        ],
      });
      expect(add.operations, isA<List>());
      expect(add.operations.first.op, 'add');
    });
  });

  group('Binding Models', () {
    test('Binding with format correctly parsed', () {
      final json = {'path': 'user.name', 'format': 'Welcome, {}'};
      final binding = Binding.fromMap(json);
      expect(binding.path, 'user.name');
      expect(binding.format, 'Welcome, {}');
      expect(binding.condition, isNull);
      expect(binding.map, isNull);
    });

    test('Binding with condition correctly parsed', () {
      final json = {
        'path': 'user.isPremium',
        'condition': {'ifValue': 'Premium', 'elseValue': 'Standard'},
      };
      final binding = Binding.fromMap(json);
      expect(binding.path, 'user.isPremium');
      expect(binding.condition, isNotNull);
      expect(binding.condition, isA<Condition>());
      expect(binding.condition!.ifValue, 'Premium');
      expect(binding.condition!.elseValue, 'Standard');
    });

    test('Binding with map correctly parsed', () {
      final json = {
        'path': 'status',
        'map': {
          'mapping': {'active': 'Online', 'inactive': 'Offline'},
          'fallback': 'Unknown',
        },
      };
      final binding = Binding.fromMap(json);
      expect(binding.path, 'status');
      expect(binding.map, isNotNull);
      expect(binding.map, isA<MapTransformer>());
      expect(binding.map!.mapping['active'], 'Online');
      expect(binding.map!.fallback, 'Unknown');
    });

    test('Binding toJson produces original map', () {
      final json = {
        'path': 'status',
        'map': {
          'mapping': {'active': 'Online'},
          'fallback': 'Unknown',
        },
      };
      final binding = Binding.fromMap(json);
      expect(binding.toJson(), equals(json));
    });
  });
}

// --- Mock Data ---

final Map<String, Object?> catalogJson =
    json.decode('''
{
  "catalogVersion": "1.0.0",
  "items": {
    "Text": {
      "properties": {
        "data": {
          "type": "string",
          "description": "The text to display."
        }
      },
      "required": ["data"]
    },
    "Container": {
      "properties": {
        "child": {
          "type": "widget"
        },
        "alignment": {
          "type": "string",
          "default": "center",
          "enum": ["center", "topLeft", "bottomRight"]
        }
      }
    },
    "Button": {
      "properties": {},
      "events": {
        "onPressed": {
          "type": "object",
          "properties": {}
        }
      }
    }
  }
}
''')
        as Map<String, Object?>;

final Map<String, Object?> packetJson =
    json.decode('''
{
  "formatVersion": "1.0.0",
  "layout": {
    "root": "root_container",
    "nodes": [
      {
        "id": "root_container",
        "type": "Container",
        "properties": {
          "child": "hello_text"
        },
        "bindings": {
          "color": {
            "path": "brandColor"
          }
        }
      },
      {
        "id": "hello_text",
        "type": "Text",
        "bindings": {
          "data": {
            "path": "title"
          }
        }
      },
      {
        "id": "my_list_view",
        "type": "ListView",
        "itemTemplate": {
          "id": "item_template",
          "type": "Text"
        }
      }
    ]
  },
  "state": {
    "title": "Hello, FCP!",
    "brandColor": "blue"
  }
}
''')
        as Map<String, Object?>;
