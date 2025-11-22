// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:catalog_gallery/main.dart';
import 'package:file/memory.dart';
import 'package:file/src/interface/directory.dart';
import 'package:file/src/interface/file.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Smoke test', (WidgetTester tester) async {
    final fs = MemoryFileSystem();
    // Build the app and trigger a frame.
    await tester.pumpWidget(CatalogGalleryApp(fs: fs));
    expect(find.text('Catalog Gallery'), findsOneWidget);
  });

  testWidgets('Loads samples from MemoryFileSystem', (
    WidgetTester tester,
  ) async {
    final fs = MemoryFileSystem();
    final Directory samplesDir = fs.directory('/samples')..createSync();
    final File sampleFile = samplesDir.childFile('test.sample');
    sampleFile.writeAsStringSync('''
name: Test Sample
description: This is a test sample to verify the parser.
---
{"surfaceUpdate": {"surfaceId": "default", "components": [{"id": "text1", "component": {"Text": {"text": {"literalString": "Hello World"}}}}]}}
{"beginRendering": {"surfaceId": "default", "root": "text1"}}
''');

    await tester.pumpWidget(CatalogGalleryApp(samplesDir: samplesDir, fs: fs));
    await tester.pumpAndSettle();

    // Verify that the "Samples" tab is present (since we provided a valid
    // samplesDir).
    expect(find.text('Samples'), findsOneWidget);

    // Tap on the Samples tab.
    await tester.tap(find.text('Samples'));
    await tester.pumpAndSettle();

    // Verify that the sample file is listed.
    // Verify that the sample file is listed.
    expect(find.text('test'), findsOneWidget);
  });

  testWidgets('Loads sample with CreateSurface before SurfaceUpdate', (
    WidgetTester tester,
  ) async {
    final fs = MemoryFileSystem();
    final Directory samplesDir = fs.directory('/samples')..createSync();
    final File sampleFile = samplesDir.childFile('ordered.sample');
    sampleFile.writeAsStringSync('''
name: Ordered Sample
description: Testing order.
---
{"createSurface": {"surfaceId": "s1"}}
{"surfaceUpdate": {"surfaceId": "s1", "components": [{"id": "root", "props": {"component": "Text", "text": {"literalString": "Ordered Success"}}}]}}
''');

    await tester.pumpWidget(Container()); // Clear previous widget tree
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      CatalogGalleryApp(key: UniqueKey(), samplesDir: samplesDir, fs: fs),
    );
    await tester.pumpAndSettle();

    // Tap on the Samples tab to load the view
    await tester.tap(find.text('Samples'));
    await tester.pumpAndSettle();

    // Verify sample is listed
    expect(find.text('ordered'), findsOneWidget);

    // Tap on sample
    await tester.tap(find.text('ordered'));
    await tester.pumpAndSettle();

    // Verify surface is created and content is shown
    expect(find.text('s1'), findsOneWidget); // Surface tab
    expect(find.text('Ordered Success'), findsOneWidget); // Content
  });
}
