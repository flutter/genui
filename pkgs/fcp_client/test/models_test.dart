import 'dart:convert';
import 'package:fcp_client/fcp_client.dart';
import 'package:fcp_client/src/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FCP Models', () {
    test('WidgetLibraryManifest correctly parsed', () {
      final manifest = WidgetLibraryManifest(manifestJson);
      expect(manifest.manifestVersion, '1.0.0');
      expect(manifest.widgets, isA<Map>());
      expect(manifest.widgets.keys, contains('Text'));
    });

    test('WidgetDefinition correctly parsed', () {
      final widgets = manifestJson['widgets']! as Map<String, Object?>;
      final textWidget = widgets['Text']! as Map<String, Object?>;
      final widgetDef = WidgetDefinition(textWidget);
      expect(widgetDef.properties, isA<Map>());
      expect(widgetDef.properties.keys, contains('data'));
      expect(widgetDef.events, isNull);
    });

    test('PropertyDefinition correctly parsed', () {
      final widgets = manifestJson['widgets']! as Map<String, Object?>;
      final textWidget = widgets['Text']! as Map<String, Object?>;
      final properties = textWidget['properties']! as Map<String, Object?>;
      final dataProperty = properties['data']! as Map<String, Object?>;
      final propDef = PropertyDefinition(dataProperty);
      expect(propDef.type, 'String');
      expect(propDef.isRequired, true);
      expect(propDef.defaultValue, isNull);
    });

    test('DynamicUIPacket correctly parsed', () {
      final packet = DynamicUIPacket(packetJson);
      expect(packet.formatVersion, '1.0.0');
      expect(packet.layout, isA<Layout>());
      expect(packet.state, isA<Map>());
      expect(packet.state['title'], 'Hello, FCP!');
    });

    test('Layout correctly parsed', () {
      final layoutMap = packetJson['layout']! as Map<String, Object?>;
      final layout = Layout(layoutMap);
      expect(layout.root, 'root_container');
      expect(layout.nodes, isA<List<WidgetNode>>());
      expect(layout.nodes.length, 3);
    });

    test('WidgetNode correctly parsed', () {
      final layoutMap = packetJson['layout']! as Map<String, Object?>;
      final nodes = layoutMap['nodes']! as List<Object?>;
      final firstNodeMap = nodes[0]! as Map<String, Object?>;
      final node = WidgetNode(firstNodeMap);
      expect(node.id, 'root_container');
      expect(node.type, 'Container');
      expect(node.properties, isA<Map>());
      expect(node.properties!['child'], 'hello_text');
      expect(node.bindings, isNotNull);
      expect(node.itemTemplate, isNull);
    });

    test('WidgetNode correctly parsed with itemTemplate', () {
      final layoutMap = packetJson['layout']! as Map<String, Object?>;
      final nodes = layoutMap['nodes']! as List<Object?>;
      // Find the node with the itemTemplate for this test
      final listNodeMap =
          nodes.firstWhere(
                (n) => (n as Map<String, Object?>)['id'] == 'my_list_view',
              )
              as Map<String, Object?>;

      final node = WidgetNode(listNodeMap);
      expect(node.id, 'my_list_view');
      expect(node.type, 'ListView');
      expect(node.itemTemplate, isNotNull);
      expect(node.itemTemplate, isA<WidgetNode>());
      expect(node.itemTemplate!.id, 'item_template');
      expect(node.itemTemplate!.type, 'Text');
    });

    test('WidgetDefinition correctly parsed with events', () {
      final widgets = manifestJson['widgets']! as Map<String, Object?>;
      final buttonWidget = widgets['Button']! as Map<String, Object?>;
      final widgetDef = WidgetDefinition(buttonWidget);
      expect(widgetDef.events, isNotNull);
      expect(widgetDef.events, isA<Map<String, Object?>>());
      expect(widgetDef.events!.containsKey('onPressed'), isTrue);
    });

    test('PropertyDefinition correctly parsed for Enum', () {
      final widgets = manifestJson['widgets']! as Map<String, Object?>;
      final containerWidget = widgets['Container']! as Map<String, Object?>;
      final properties = containerWidget['properties']! as Map<String, Object?>;
      final alignmentProp = properties['alignment']! as Map<String, Object?>;
      final propDef = PropertyDefinition(alignmentProp);
      expect(propDef.type, 'Enum');
      expect(propDef.isRequired, isFalse);
      expect(propDef.defaultValue, 'center');
      expect(propDef.values, isNotNull);
      expect(propDef.values, contains('center'));
      expect(propDef.values, contains('topLeft'));
    });

    test('EventPayload correctly parsed', () {
      final payload = EventPayload({
        'sourceWidgetId': 'my_button',
        'eventName': 'onPressed',
        'arguments': {'clickCount': 1},
      });
      expect(payload.sourceWidgetId, 'my_button');
      expect(payload.eventName, 'onPressed');
      expect(payload.arguments, isA<Map>());
      expect(payload.arguments!['clickCount'], 1);
    });

    test('StateUpdate correctly parsed', () {
      final update = StateUpdate({
        'patches': [
          {'op': 'replace', 'path': '/title', 'value': 'New Title'},
        ],
      });
      expect(update.patches, isA<List>());
      expect(update.patches.first['op'], 'replace');
    });

    test('LayoutUpdate correctly parsed', () {
      final update = LayoutUpdate({
        'operations': <Map<String, Object?>>[
          {'op': 'add', 'nodes': <Object?>[]},
        ],
      });
      expect(update.operations, isA<List>());
      expect(update.operations.first.op, 'add');
    });
  });

  group('Binding Models', () {
    test('Binding with format correctly parsed', () {
      final json = {'path': 'user.name', 'format': 'Welcome, {}'};
      final binding = Binding.fromJson(json);
      expect(binding.path, 'user.name');
      expect(binding.format, 'Welcome, {}');
      expect(binding.condition, isNull);
      expect(binding.map, isNull);
    });

    test('Binding with condition correctly parsed', () {
      final json = {
        'path': 'user.isPremium',
        'condition': {'if': 'Premium', 'else': 'Standard'},
      };
      final binding = Binding.fromJson(json);
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
      final binding = Binding.fromJson(json);
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
      final binding = Binding.fromJson(json);
      expect(binding.toJson(), equals(json));
    });
  });
}

// --- Mock Data ---

final Map<String, Object?> manifestJson =
    json.decode('''
{
  "manifestVersion": "1.0.0",
  "widgets": {
    "Text": {
      "properties": {
        "data": {
          "type": "String",
          "isRequired": true
        }
      }
    },
    "Container": {
      "properties": {
        "child": {
          "type": "WidgetId"
        },
        "alignment": {
          "type": "Enum",
          "defaultValue": "center",
          "values": ["center", "topLeft", "bottomRight"]
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
