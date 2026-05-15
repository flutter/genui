// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:catalog_gallery/main.dart';
import 'package:file/memory.dart';
import 'package:file/src/interface/directory.dart';
import 'package:file/src/interface/file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'src/test_http_client.dart';

void main() {
  testWidgets('Smoke test', (WidgetTester tester) async {
    final fs = MemoryFileSystem();
    // Build the app and trigger a frame.
    await tester.pumpWidget(
      CatalogGalleryApp(fs: fs, splashFactory: NoSplash.splashFactory),
    );
    expect(find.text('Catalog Gallery'), findsOneWidget);
  });

  testWidgets('Loads samples from MemoryFileSystem', (
    WidgetTester tester,
  ) async {
    HttpOverrides.global = TestHttpOverrides();
    addTearDown(() => HttpOverrides.global = null);
    final fs = MemoryFileSystem();
    final Directory samplesDir = fs.directory('/samples')..createSync();
    final File sampleFile = samplesDir.childFile('test.sample');
    sampleFile.writeAsStringSync('''
name: Test Sample
description: A test description
---
{"surfaceUpdate": {"surfaceId": "default", "components": [{"id": "text1", "component": {"Text": {"text": "Hello"}}}]}}
''');

    await tester.pumpWidget(
      CatalogGalleryApp(
        samplesDir: samplesDir,
        fs: fs,
        splashFactory: NoSplash.splashFactory,
      ),
    );
    await tester.pumpAndSettle();

    // Verify that the "Samples" tab is present (since we provided a valid
    // samplesDir).
    expect(find.text('Samples'), findsOneWidget);

    // Tap on the Samples tab.
    await tester.tap(find.text('Samples'));
    await tester.pumpAndSettle();

    // Verify that the sample file is listed.
    expect(find.text('test'), findsOneWidget);
  });
}
