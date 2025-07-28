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
    'widgets': <String, Object?>{
      'Container': {
        'properties': <String, Object?>{
          'child': {'type': 'WidgetId'},
        },
      },
      'Text': {
        'properties': <String, Object?>{
          'data': {'type': 'String', 'isRequired': true},
        },
      },
      'Column': {
        'properties': <String, Object?>{
          'children': {'type': 'ListOfWidgetIds'},
        },
      },
      'EventButton': {
        'properties': <String, Object?>{
          'child': {'type': 'WidgetId'},
        },
      },
    },
  });

  DynamicUIPacket createPacket(Map<String, Object?> layout) {
    return DynamicUIPacket({
      'formatVersion': '1.0.0',
      'layout': layout,
      'state': <String, Object?>{'title': 'Test Title'},
    });
  }

  group('FcpView Rendering', () {
    testWidgets('renders a simple widget tree correctly', (
      WidgetTester tester,
    ) async {
      final packet = createPacket({
        'root': 'root_text',
        'nodes': [
          {
            'id': 'root_text',
            'type': 'Text',
            'properties': {'data': 'Hello'},
          },
        ],
      });

      await tester.pumpWidget(
        MaterialApp(
          home: FcpView(
            packet: packet,
            registry: testRegistry,
            manifest: testManifest,
          ),
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('renders a nested widget tree correctly', (
      WidgetTester tester,
    ) async {
      final packet = createPacket({
        'root': 'root_container',
        'nodes': [
          {
            'id': 'root_container',
            'type': 'Container',
            'properties': {'child': 'child_text'},
          },
          {
            'id': 'child_text',
            'type': 'Text',
            'properties': {'data': 'Nested'},
          },
        ],
      });

      await tester.pumpWidget(
        MaterialApp(
          home: FcpView(
            packet: packet,
            registry: testRegistry,
            manifest: testManifest,
          ),
        ),
      );

      expect(find.byType(Container), findsOneWidget);
      expect(find.text('Nested'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(Container),
          matching: find.byType(Text),
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders a widget with multiple children (Column)', (
      WidgetTester tester,
    ) async {
      final packet = createPacket({
        'root': 'root_column',
        'nodes': [
          {
            'id': 'root_column',
            'type': 'Column',
            'properties': {
              'children': ['child1', 'child2'],
            },
          },
          {
            'id': 'child1',
            'type': 'Text',
            'properties': {'data': 'First'},
          },
          {
            'id': 'child2',
            'type': 'Text',
            'properties': {'data': 'Second'},
          },
        ],
      });

      await tester.pumpWidget(
        MaterialApp(
          home: FcpView(
            packet: packet,
            registry: testRegistry,
            manifest: testManifest,
          ),
        ),
      );

      expect(find.byType(Column), findsOneWidget);
      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
    });
  });

  group('FcpView Error Handling', () {
    testWidgets('displays an error widget for unregistered widget type', (
      WidgetTester tester,
    ) async {
      final packet = createPacket({
        'root': 'root_widget',
        'nodes': [
          {'id': 'root_widget', 'type': 'UnknownWidget'},
        ],
      });

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
          'FCP Error: No builder registered for widget type "UnknownWidget".',
        ),
        findsOneWidget,
      );
    });

    testWidgets('displays an error widget for node not found in layout', (
      WidgetTester tester,
    ) async {
      final packet = createPacket({
        'root': 'root_widget',
        'nodes': [
          // The root_widget is not defined in the nodes list
        ],
      });

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
        find.text('FCP Error: Node with id "root_widget" not found in layout.'),
        findsOneWidget,
      );
    });

    testWidgets('does not build a missing child node and does not error', (
      WidgetTester tester,
    ) async {
      final packet = createPacket({
        'root': 'root_container',
        'nodes': [
          {
            'id': 'root_container',
            'type': 'Container',
            'properties': {'child': 'non_existent_child'},
          },
        ],
      });

      await tester.pumpWidget(
        MaterialApp(
          home: FcpView(
            packet: packet,
            registry: testRegistry,
            manifest: testManifest,
          ),
        ),
      );

      // The container should be there, but its child should not be.
      // No error widget should be displayed.
      expect(find.byType(Container), findsOneWidget);
      expect(find.byType(Text), findsNothing);
      expect(find.byType(ErrorWidget), findsNothing);
    });

    testWidgets('displays an error widget for cyclical layouts', (
      WidgetTester tester,
    ) async {
      final packet = createPacket({
        'root': 'node_a',
        'nodes': [
          {
            'id': 'node_a',
            'type': 'Container',
            'properties': {'child': 'node_b'},
          },
          {
            'id': 'node_b',
            'type': 'Container',
            'properties': {'child': 'node_a'},
          },
        ],
      });

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
          'FCP Error: Cyclical layout detected. Node "node_a" is already in '
          'the build path.',
        ),
        findsOneWidget,
      );
    });
  });

  group('FcpView State & Binding', () {
    testWidgets('renders correctly with a simple state binding', (
      WidgetTester tester,
    ) async {
      final packet = DynamicUIPacket({
        'formatVersion': '1.0.0',
        'layout': {
          'root': 'root_text',
          'nodes': [
            {
              'id': 'root_text',
              'type': 'Text',
              'bindings': {
                'data': {'path': 'message'},
              },
            },
          ],
        },
        'state': {'message': 'Bound Message'},
      });

      await tester.pumpWidget(
        MaterialApp(
          home: FcpView(
            packet: packet,
            registry: testRegistry,
            manifest: testManifest,
          ),
        ),
      );

      expect(find.text('Bound Message'), findsOneWidget);
    });

    testWidgets(
      'updates the view when a new packet with new state is provided',
      (WidgetTester tester) async {
        var packet = DynamicUIPacket({
          'formatVersion': '1.0.0',
          'layout': {
            'root': 'root_text',
            'nodes': [
              {
                'id': 'root_text',
                'type': 'Text',
                'bindings': {
                  'data': {'path': 'message'},
                },
              },
            ],
          },
          'state': {'message': 'Initial Message'},
        });

        await tester.pumpWidget(
          MaterialApp(
            home: FcpView(
              packet: packet,
              registry: testRegistry,
              manifest: testManifest,
            ),
          ),
        );

        expect(find.text('Initial Message'), findsOneWidget);
        expect(find.text('Updated Message'), findsNothing);

        // Create a new packet with updated state
        packet = DynamicUIPacket({
          'formatVersion': '1.0.0',
          'layout': {
            'root': 'root_text',
            'nodes': [
              {
                'id': 'root_text',
                'type': 'Text',
                'bindings': {
                  'data': {'path': 'message'},
                },
              },
            ],
          },
          'state': {'message': 'Updated Message'},
        });

        // Rebuild the widget with the new packet
        await tester.pumpWidget(
          MaterialApp(
            home: FcpView(
              packet: packet,
              registry: testRegistry,
              manifest: testManifest,
            ),
          ),
        );

        expect(find.text('Initial Message'), findsNothing);
        expect(find.text('Updated Message'), findsOneWidget);
      },
    );
  });

  group('FcpView Events', () {
    testWidgets('fires an event with arguments correctly', (
      WidgetTester tester,
    ) async {
      EventPayload? capturedPayload;

      final eventRegistry = WidgetRegistry()
        ..register(
          'EventButton',
          (context, node, properties, children) => ElevatedButton(
            onPressed: () {
              FcpProvider.of(context)?.onEvent?.call(
                EventPayload({
                  'sourceWidgetId': node.id,
                  'eventName': 'onPressed',
                  'arguments': {'value': 'test_value'},
                }),
              );
            },
            child: children['child'] as Widget?,
          ),
        );

      final packet = createPacket({
        'root': 'button',
        'nodes': [
          {
            'id': 'button',
            'type': 'EventButton',
            'properties': {'child': 'button_text'},
          },
          {
            'id': 'button_text',
            'type': 'Text',
            'properties': {'data': 'Tap Me'},
          },
        ],
      });

      await tester.pumpWidget(
        MaterialApp(
          home: FcpView(
            packet: packet,
            registry: eventRegistry,
            manifest: testManifest,
            onEvent: (payload) {
              capturedPayload = payload;
            },
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(capturedPayload, isNotNull);
      expect(capturedPayload!.sourceWidgetId, 'button');
      expect(capturedPayload!.eventName, 'onPressed');
      expect(capturedPayload!.arguments, isA<Map>());
      expect(capturedPayload!.arguments!['value'], 'test_value');
    });
  });

  group('FcpViewController', () {
    testWidgets('patches state and updates UI correctly', (
      WidgetTester tester,
    ) async {
      final controller = FcpViewController();
      final packet = DynamicUIPacket({
        'formatVersion': '1.0.0',
        'layout': {
          'root': 'root_text',
          'nodes': [
            {
              'id': 'root_text',
              'type': 'Text',
              'bindings': {
                'data': {'path': 'message'},
              },
            },
          ],
        },
        'state': {'message': 'Initial Message'},
      });

      await tester.pumpWidget(
        MaterialApp(
          home: FcpView(
            packet: packet,
            registry: testRegistry,
            manifest: testManifest,
            controller: controller,
          ),
        ),
      );

      expect(find.text('Initial Message'), findsOneWidget);

      // Create a patch and send it through the controller
      final update = StateUpdate({
        'patches': [
          {'op': 'replace', 'path': '/message', 'value': 'Patched Message'},
        ],
      });
      controller.patchState(update);

      // Rebuild the widget
      await tester.pump();

      expect(find.text('Initial Message'), findsNothing);
      expect(find.text('Patched Message'), findsOneWidget);
    });

    group('FcpViewController Layout Updates', () {
      testWidgets('patches layout with "add" and updates UI', (
        WidgetTester tester,
      ) async {
        final controller = FcpViewController();
        final packet = createPacket({
          'root': 'root_column',
          'nodes': [
            {
              'id': 'root_column',
              'type': 'Column',
              'properties': {
                'children': ['child1'],
              },
            },
            {
              'id': 'child1',
              'type': 'Text',
              'properties': {'data': 'First'},
            },
          ],
        });

        await tester.pumpWidget(
          MaterialApp(
            home: FcpView(
              packet: packet,
              registry: testRegistry,
              manifest: testManifest,
              controller: controller,
            ),
          ),
        );

        expect(find.text('First'), findsOneWidget);
        expect(find.text('Second'), findsNothing);

        // Add a new widget to the layout
        final update = LayoutUpdate({
          'operations': [
            {
              'op': 'add',
              'nodes': [
                {
                  'id': 'child2',
                  'type': 'Text',
                  'properties': {'data': 'Second'},
                },
              ],
            },
            {
              'op': 'update',
              'nodes': [
                {
                  'id': 'root_column',
                  'type': 'Column',
                  'properties': {
                    'children': ['child1', 'child2'],
                  },
                },
              ],
            },
          ],
        });
        controller.patchLayout(update);
        await tester.pump();

        expect(find.text('First'), findsOneWidget);
        expect(find.text('Second'), findsOneWidget);
      });

      testWidgets('patches layout with "remove" and updates UI', (
        WidgetTester tester,
      ) async {
        final controller = FcpViewController();
        final packet = createPacket({
          'root': 'root_column',
          'nodes': [
            {
              'id': 'root_column',
              'type': 'Column',
              'properties': {
                'children': ['child1', 'child2'],
              },
            },
            {
              'id': 'child1',
              'type': 'Text',
              'properties': {'data': 'First'},
            },
            {
              'id': 'child2',
              'type': 'Text',
              'properties': {'data': 'Second'},
            },
          ],
        });

        await tester.pumpWidget(
          MaterialApp(
            home: FcpView(
              packet: packet,
              registry: testRegistry,
              manifest: testManifest,
              controller: controller,
            ),
          ),
        );

        expect(find.text('First'), findsOneWidget);
        expect(find.text('Second'), findsOneWidget);

        // Remove the second child
        final update = LayoutUpdate({
          'operations': [
            {
              'op': 'remove',
              'ids': ['child2'],
            },
            {
              'op': 'update',
              'nodes': [
                {
                  'id': 'root_column',
                  'type': 'Column',
                  'properties': {
                    'children': ['child1'],
                  },
                },
              ],
            },
          ],
        });
        controller.patchLayout(update);
        await tester.pump();

        expect(find.text('First'), findsOneWidget);
        expect(find.text('Second'), findsNothing);
      });

      testWidgets('patches layout with "update" and updates UI', (
        WidgetTester tester,
      ) async {
        final controller = FcpViewController();
        final packet = createPacket({
          'root': 'text_widget',
          'nodes': [
            {
              'id': 'text_widget',
              'type': 'Text',
              'properties': {'data': 'Initial Text'},
            },
          ],
        });

        await tester.pumpWidget(
          MaterialApp(
            home: FcpView(
              packet: packet,
              registry: testRegistry,
              manifest: testManifest,
              controller: controller,
            ),
          ),
        );

        expect(find.text('Initial Text'), findsOneWidget);

        // Update the text property
        final update = LayoutUpdate({
          'operations': [
            {
              'op': 'update',
              'nodes': [
                {
                  'id': 'text_widget',
                  'type': 'Text',
                  'properties': {'data': 'Updated Text'},
                },
              ],
            },
          ],
        });
        controller.patchLayout(update);
        await tester.pump();

        expect(find.text('Initial Text'), findsNothing);
        expect(find.text('Updated Text'), findsOneWidget);
      });
    });
  });
}
