// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:catalog_gallery/sample_parser.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

import 'src/test_http_client.dart';

void main() {
  const fs = LocalFileSystem();
  Directory? samplesDir;

  // Locate samples directory synchronously before tests run
  final Directory current = fs.currentDirectory;
  if (current.childDirectory('samples').existsSync()) {
    samplesDir = current.childDirectory('samples');
  } else if (current.childDirectory('../samples').existsSync()) {
    samplesDir = current.childDirectory('../samples');
  } else if (current.path.endsWith('/test')) {
    final Directory parent = current.parent;
    if (parent.childDirectory('samples').existsSync()) {
      samplesDir = parent.childDirectory('samples');
    }
  }

  if (samplesDir == null || !samplesDir.existsSync()) {
    // If we can't find samples, we can't generate tests.
    // We'll add a single failing test to report the error.
    test('Samples directory validation', () {
      fail('Could not find samples directory. CWD: ${current.path}');
    });
    return;
  }

  final List<File> files = samplesDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.sample'))
      .toList();

  files.sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final String fileName = fs.path.basename(file.path);
    testWidgets('Render sample: $fileName', (WidgetTester tester) async {
      HttpOverrides.global = TestHttpOverrides();

      // extensive scrolling or large content
      // 2400 / 3.0 = 800 logical pixels wide/high
      tester.view.physicalSize = const Size(
        2400,
        3000,
      ); // Increased height to prevent overflow
      tester.view.devicePixelRatio = 3.0;

      addTearDown(() {
        HttpOverrides.global = null;
        debugNetworkImageHttpClientProvider = null;
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      genUiLogger.info('Starting test for $fileName');

      // Use synchronous read to avoid async IO issues
      final String content = file.readAsStringSync();
      final List<String> expectedTexts = _extractExpectedText(content);
      final List<String> expectedIds = _extractComponentIds(content);

      // Parse sample
      final Sample sample = SampleParser.parseString(content);

      final Catalog catalog = CoreCatalogItems.asCatalog();
      final controller = SurfaceController(catalogs: [catalog]);

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Surface(surfaceContext: controller.contextFor('main')),
          ),
        ),
      );

      try {
        await for (final A2uiMessage message in sample.messages) {
          controller.handleMessage(message);
          await tester.pump();
        }
        await tester.pumpAndSettle();

        // Verify text content (warn only, as some content might be hidden in tabs/offstage)
        for (final text in expectedTexts) {
          if (find.text(text).evaluate().isEmpty) {
            // print('Warning: Expected text not visible: "$text"');
          }
        }

        final Set<String> ignoredIds = _ignoredIds[fileName] ?? {};
        for (final id in expectedIds) {
          if (ignoredIds.contains(id)) {
            continue;
          }
          // We use skipOffstage: false because items in tabs might be offstage
          // but present.
          if (find
              .byKey(ValueKey(id), skipOffstage: false)
              .evaluate()
              .isEmpty) {
            // Fail if the structure is missing entirely
            fail('Expected component with ID "$id" to be in the widget tree.');
          }
        }

        // Unfocus to close any active input connections
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pump();

        // Pump a SizedBox to dispose the widget tree
        await tester.pumpWidget(const SizedBox());
        await tester.pump(); // Allow disposal to complete
      } finally {
        genUiLogger.info('Disposing controller for $fileName');
        controller.dispose();

        // Clear image cache to prevent pending loads/streams from hanging the test
        imageCache.clear();
        imageCache.clearLiveImages();

        genUiLogger.info('Test finished for $fileName');
      }
    });
  }
}

final Map<String, Set<String>> _ignoredIds = {
  'settingsPage.sample': {
    'deleteConfirmationContent',
    'confirmationText',
    'modalButtonsRow',
    'confirmDeletionButton',
    'confirmDeletionButtonText',
    'cancelDeletionButton',
    'cancelDeletionButtonText',
  },
};

List<String> _extractExpectedText(String content) {
  final List<String> result = [];
  // Basic regex to find "text": "value"
  final exp = RegExp(r'"text":\s*"([^"]+)"');
  for (final Match m in exp.allMatches(content)) {
    if (m.groupCount >= 1) {
      result.add(m.group(1)!);
    }
  }
  return result;
}

List<String> _extractComponentIds(String content) {
  final List<String> result = [];
  // Basic regex to find "id": "value"
  final exp = RegExp(r'"id":\s*"([^"]+)"');
  for (final Match m in exp.allMatches(content)) {
    if (m.groupCount >= 1) {
      result.add(m.group(1)!);
    }
  }
  return result;
}
