import 'package:fcp_client/fcp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final testRegistry = WidgetRegistry()
    ..register(
      'Container',
      (context, node, properties, children) =>
          Container(child: children['child'] as Widget?),
    )
    ..register(
      'Text',
      (context, node, properties, children) =>
          Text(properties['data'] as String? ?? ''),
    )
    ..register(
      'Column',
      (context, node, properties, children) =>
          Column(children: (children['children'] as List<Widget>?) ?? []),
    );

  final testManifest = WidgetLibraryManifest({
    'manifestVersion': '1.0.0',
    'dataTypes': {},
    'widgets': {
      'Container': {
        'properties': {
          'child': {'type': 'Widget'},
        },
      },
      'Text': {
        'properties': {
          'data': {'type': 'String'},
        },
      },
      'Column': {
        'properties': {
          'children': {'type': 'List<Widget>'},
        },
      },
      'ListViewBuilder': {
        'properties': {
          'data': {'type': 'List'},
          'itemTemplate': {'type': 'Widget'},
        },
      },
    },
  });

  DynamicUIPacket createPacket(
    Map<String, Object?> layout, [
    Map<String, Object?>? state,
  ]) {
    return DynamicUIPacket({
      'formatVersion': '1.0.0',
      'layout': layout,
      'state': state ?? {'title': 'Test Title'},
    });
  }

  group('ListViewBuilder', () {
    testWidgets('renders a list of items from state', (
      WidgetTester tester,
    ) async {
      final packet = createPacket(
        {
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
        {
          'items': [
            {'name': 'Item 1'},
            {'name': 'Item 2'},
            {'name': 'Item 3'},
          ],
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FcpView(
            packet: packet,
            registry: testRegistry,
            manifest: testManifest,
          ),
        ),
      );

      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 3'), findsOneWidget);
    });

    testWidgets('displays error if itemTemplate is missing', (
      WidgetTester tester,
    ) async {
      final packet = createPacket(
        {
          'root': 'my_list',
          'nodes': [
            {
              'id': 'my_list',
              'type': 'ListViewBuilder',
              'bindings': {
                'data': {'path': 'items'},
              },
            },
          ],
        },
        {'items': []},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FcpView(
            packet: packet,
            registry: testRegistry,
            manifest: testManifest,
          ),
        ),
      );

      expect(
        find.text(
          'FCP Error: ListViewBuilder "my_list" is missing itemTemplate.',
        ),
        findsOneWidget,
      );
    });
  });
}
