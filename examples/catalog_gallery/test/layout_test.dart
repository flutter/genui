// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:catalog_gallery/sample_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

void main() {
  testWidgets('cinemaSeatSelection sample renders without error', (
    WidgetTester tester,
  ) async {
    final file = File('samples/cinemaSeatSelection.1.sample');
    final String content = file.readAsStringSync();
    final Sample sample = SampleParser.parseString(content);

    final controller = GenUiController(
      catalogs: [CoreCatalogItems.asCatalog()],
    );

    await for (final A2uiMessage message in sample.messages) {
      if (message is CreateSurface) {
        // We manually inject standardCatalog since createSurface might ref
        // external URL in this test environment, we just assume standardCatalog
        // is available
      }
      controller.handleMessage(message);
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GenUiSurface(genUiContext: controller.contextFor('main')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Select Seats'), findsOneWidget);
  });

  testWidgets('nestedLayoutRecursive sample renders without error', (
    WidgetTester tester,
  ) async {
    final file = File('samples/nestedLayoutRecursive.1.sample');
    final String content = file.readAsStringSync();
    final Sample sample = SampleParser.parseString(content);

    final controller = GenUiController(
      catalogs: [CoreCatalogItems.asCatalog()],
    );

    await for (final A2uiMessage message in sample.messages) {
      controller.handleMessage(message);
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GenUiSurface(genUiContext: controller.contextFor('main')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Deep content'), findsOneWidget);
  });
}
