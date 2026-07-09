// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:a2ui_core/a2ui_core.dart' as core;
import 'package:catalog_gallery/sample_parser.dart';
import 'package:file/file.dart' as file_pkg;
import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

import 'src/sample_locator.dart';
import 'src/test_http_client.dart';

void main() {
  final file_pkg.Directory? samplesDir = findSamplesDir();
  if (samplesDir == null) {
    test('Samples directory validation', () {
      fail('Could not find samples directory.');
    });
    return;
  }

  testWidgets('cinemaSeatSelection sample renders without error', (
    WidgetTester tester,
  ) async {
    HttpOverrides.global = TestHttpOverrides();
    addTearDown(() => HttpOverrides.global = null);
    addTearDown(() => debugNetworkImageHttpClientProvider = null);

    final file = File('${samplesDir.path}/cinemaSeatSelection.sample');
    final String content = file.readAsStringSync();
    final Sample sample = SampleParser.parseString(content);

    final controller = SurfaceController(
      catalogs: [BasicCatalogItems.asCatalog()],
    );

    await for (final core.A2uiMessage message in sample.messages) {
      var messageToProcess = message;
      if (message is core.CreateSurfaceMessage) {
        // We manually inject the basic catalog since createSurface might ref
        // external URL in this test environment, we just assume the basic
        // catalog is available
        messageToProcess = core.CreateSurfaceMessage(
          surfaceId: message.surfaceId,
          catalogId: basicCatalogId,
          surfaceProperties: message.surfaceProperties,
          sendDataModel: message.sendDataModel,
        );
      }
      controller.handleMessage(messageToProcess);
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Surface(surfaceContext: controller.contextFor('main')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Select Seats'), findsOneWidget);
  });

  testWidgets('nestedLayoutRecursive sample renders without error', (
    WidgetTester tester,
  ) async {
    debugNetworkImageHttpClientProvider = TestHttpClient.new;
    // addTearDown(() => debugNetworkImageHttpClientProvider = null);

    try {
      final file = File('${samplesDir.path}/nestedLayoutRecursive.sample');
      final String content = file.readAsStringSync();
      final Sample sample = SampleParser.parseString(content);

      final controller = SurfaceController(
        catalogs: [BasicCatalogItems.asCatalog()],
      );

      await for (final core.A2uiMessage message in sample.messages) {
        controller.handleMessage(message);
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Surface(surfaceContext: controller.contextFor('main')),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Deep content'), findsOneWidget);
    } finally {
      debugNetworkImageHttpClientProvider = null;
    }
  });
}
