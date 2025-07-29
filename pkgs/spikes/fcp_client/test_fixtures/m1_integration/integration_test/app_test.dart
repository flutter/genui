import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fcp_client/fcp_client.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  WidgetCatalogRegistry createTestRegistry() {
    return WidgetCatalogRegistry()
      ..register(
        CatalogItem(
          name: 'Scaffold',
          builder: (context, node, properties, children) {
            return Scaffold(
              appBar: children['appBar'] as PreferredSizeWidget?,
              body: children['body'] as Widget?,
            );
          },
          definition: WidgetDefinition({
            'properties': {
              'appBar': {'type': 'WidgetId'},
              'body': {'type': 'WidgetId'},
            },
          }),
        ),
      )
      ..register(
        CatalogItem(
          name: 'AppBar',
          builder: (context, node, properties, children) {
            return AppBar(
              title: children['title'] as Widget?,
              automaticallyImplyLeading: false,
            );
          },
          definition: WidgetDefinition({
            'properties': {
              'title': {'type': 'WidgetId'},
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
          definition: WidgetDefinition({
            'properties': {
              'data': {'type': 'String'},
            },
          }),
        ),
      )
      ..register(
        CatalogItem(
          name: 'Center',
          builder: (context, node, properties, children) {
            return Center(child: children['child'] as Widget?);
          },
          definition: WidgetDefinition({
            'properties': {
              'child': {'type': 'WidgetId'},
            },
          }),
        ),
      );
  }

  DynamicUIPacket createTestPacket() {
    return DynamicUIPacket({
      'formatVersion': '1.0.0',
      'layout': {
        'root': 'root_scaffold',
        'nodes': [
          {
            'id': 'root_scaffold',
            'type': 'Scaffold',
            'properties': {'appBar': 'main_app_bar', 'body': 'main_center'},
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
            'id': 'main_center',
            'type': 'Center',
            'properties': {'child': 'body_text'},
          },
          {
            'id': 'body_text',
            'type': 'Text',
            'properties': {'data': 'Hello, world!'},
          },
        ],
      },
      'state': <String, Object?>{},
    });
  }

  testWidgets('renders a complete static UI', (WidgetTester tester) async {
    final registry = createTestRegistry();
    final catalog = registry.buildCatalog(catalogVersion: '1.0.0');
    final packet = createTestPacket();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MaterialApp(
        home: FcpView(packet: packet, catalog: catalog, registry: registry),
      ),
    );

    // Verify that the UI is rendered correctly.
    expect(find.text('FCP Integration Test'), findsOneWidget);
    expect(find.text('Hello, world!'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byType(Center), findsOneWidget);
  });
}
