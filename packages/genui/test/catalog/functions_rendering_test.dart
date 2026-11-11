// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore: deprecated_member_use, see https://github.com/a2ui-project/a2ui/issues/3235
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import '../test_infra/message_builders.dart';

const _urlLauncherChannel = MethodChannel('plugins.flutter.io/url_launcher');

void main() {
  late SurfaceController controller;
  final testCatalog = Catalog(
    [BasicCatalogItems.text, BasicCatalogItems.column],
    functions: BasicFunctions.all,
    catalogId: 'test_catalog',
  );

  setUp(() {
    controller = SurfaceController(catalogs: [testCatalog]);
  });

  tearDown(() {
    controller.dispose();
  });

  testWidgets('Surface renders function output correctly', (
    WidgetTester tester,
  ) async {
    const surfaceId = 'testSurface';

    // 1. Create surface
    controller.handleMessage(
      createSurface(surfaceId: surfaceId, catalogId: 'test_catalog'),
    );

    // 2. Update data model
    controller.handleMessage(
      updateDataModel(
        surfaceId: surfaceId,
        path: DataPath.root,
        value: {'count': 2},
      ),
    );

    // 3. Update components with a function call
    final components = [
      const Component(
        id: 'root',
        type: 'Column',
        properties: {
          'children': ['cartSummaryText'],
        },
      ),
      const Component(
        id: 'cartSummaryText',
        type: 'Text',
        properties: {
          'text': {
            'call': 'pluralize',
            'args': {
              'count': {'path': '/count'},
              'zero': 'No items',
              'one': 'One item',
              'other': 'Multiple items',
            },
            'returnType': 'string',
          },
        },
      ),
    ];

    controller.handleMessage(
      updateComponents(
        surfaceId: surfaceId,
        components: components.map((c) => c.toJson()).toList(),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Surface(surfaceContext: controller.contextFor(surfaceId)),
      ),
    );
    await tester.pumpAndSettle();

    // We expect "Multiple items" because count is 2.
    expect(find.text('Multiple items'), findsOneWidget);
  });

  testWidgets('Surface blocks non-http(s) openUrl calls during render', (
    WidgetTester tester,
  ) async {
    final launchedUrls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_urlLauncherChannel, (MethodCall call) async {
          final args = call.arguments as Map<Object?, Object?>;
          if (call.method == 'canLaunch') return true;
          if (call.method == 'launch') {
            launchedUrls.add(args['url'] as String);
            return true;
          }
          return null;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_urlLauncherChannel, null);
    });

    const surfaceId = 'openUrlSurface';
    controller.handleMessage(
      createSurface(surfaceId: surfaceId, catalogId: 'test_catalog'),
    );

    final components = [
      const Component(
        id: 'root',
        type: 'Column',
        properties: {
          'children': ['intentText', 'fileText', 'jsText', 'httpsText'],
        },
      ),
      const Component(
        id: 'intentText',
        type: 'Text',
        properties: {
          'text': {
            'call': 'openUrl',
            'args': {
              'url': 'intent://open/#Intent;scheme=app;package=com.example;end',
            },
          },
        },
      ),
      const Component(
        id: 'fileText',
        type: 'Text',
        properties: {
          'text': {
            'call': 'openUrl',
            'args': {'url': 'file:///etc/hosts'},
          },
        },
      ),
      const Component(
        id: 'jsText',
        type: 'Text',
        properties: {
          'text': {
            'call': 'openUrl',
            'args': {'url': 'javascript:alert(1)'},
          },
        },
      ),
      const Component(
        id: 'httpsText',
        type: 'Text',
        properties: {
          'text': {
            'call': 'openUrl',
            'args': {'url': 'https://flutter.dev'},
          },
        },
      ),
    ];

    controller.handleMessage(
      updateComponents(
        surfaceId: surfaceId,
        components: components.map((c) => c.toJson()).toList(),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Surface(surfaceContext: controller.contextFor(surfaceId)),
      ),
    );
    await tester.pumpAndSettle();

    expect(launchedUrls, <String>['https://flutter.dev']);
  });
}
