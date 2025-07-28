// To run this test, navigate to this directory in your terminal and run:
// flutter test integration_test/app_test.dart -d macos
// (or -d linux, or -d web)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fcp_client/fcp_client.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final testRegistry = WidgetRegistry()
    ..register('Scaffold', (context, node, properties, children) {
      return Scaffold(
        appBar: children['appBar'] as PreferredSizeWidget?,
        body: children['body'],
      );
    })
    ..register('AppBar', (context, node, properties, children) {
      return AppBar(title: children['title']);
    })
    ..register(
      'Column',
      (context, node, properties, children) =>
          Column(children: (children['children'] as List<Widget>?) ?? []),
    )
    ..register('Text', (context, node, properties, children) {
      return Text(properties['data'] as String? ?? '');
    });

  final testManifest = WidgetLibraryManifest({
    'manifestVersion': '1.0.0',
    'widgets': {},
  });

  DynamicUIPacket createComplexPacket() {
    return DynamicUIPacket({
      'formatVersion': '1.0.0',
      'layout': {
        'root': 'root_scaffold',
        'nodes': [
          {
            'id': 'root_scaffold',
            'type': 'Scaffold',
            'properties': {'appBar': 'main_app_bar', 'body': 'main_column'},
          },
          {
            'id': 'main_app_bar',
            'type': 'AppBar',
            'properties': {'title': 'title_text'},
          },
          {
            'id': 'title_text',
            'type': 'Text',
            'properties': {'data': 'FCP Integration Test'},
          },
          {
            'id': 'main_column',
            'type': 'Column',
            'properties': {
              'children': ['text1', 'text2'],
            },
          },
          {
            'id': 'text1',
            'type': 'Text',
            'properties': {'data': 'First line'},
          },
          {
            'id': 'text2',
            'type': 'Text',
            'properties': {'data': 'Second line'},
          },
        ],
      },
      'state': <String, Object?>{},
    });
  }

  testWidgets('FcpView renders a complex static UI correctly', (
    WidgetTester tester,
  ) async {
    final packet = createComplexPacket();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MaterialApp(
        home: FcpView(
          packet: packet,
          registry: testRegistry,
          manifest: testManifest,
        ),
      ),
    );

    // Verify that all widgets are rendered correctly.
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('FCP Integration Test'), findsOneWidget);
    expect(find.byType(Column), findsOneWidget);
    expect(find.text('First line'), findsOneWidget);
    expect(find.text('Second line'), findsOneWidget);

    // Verify the structure.
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('FCP Integration Test'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(Column),
        matching: find.text('First line'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(Column),
        matching: find.text('Second line'),
      ),
      findsOneWidget,
    );
  });
}
