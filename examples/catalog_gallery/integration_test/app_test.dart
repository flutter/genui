// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:catalog_gallery/main.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:integration_test/integration_test.dart';
import 'package:logging/logging.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Configure logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });

  const fs = LocalFileSystem();
  Directory? samplesDir;

  // Locate samples directory synchronously before tests run
  final Directory current = fs.currentDirectory;
  if (current.childDirectory('samples').existsSync()) {
    samplesDir = current.childDirectory('samples');
  } else if (current.childDirectory('../samples').existsSync()) {
    samplesDir = current.childDirectory('../samples');
  } else if (current.path.endsWith('/integration_test')) {
    final Directory parent = current.parent;
    if (parent.childDirectory('samples').existsSync()) {
      samplesDir = parent.childDirectory('samples');
    }
  }

  if (samplesDir == null || !samplesDir.existsSync()) {
    testWidgets('Samples directory validation', (tester) async {
      fail('Could not find samples directory. CWD: ${current.path}');
    });
    return;
  }

  // Filter for .sample files
  final List<File> files = samplesDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.sample'))
      .toList();

  files.sort((a, b) => a.path.compareTo(b.path));

  testWidgets('catalog_gallery smoke test - verify initial state', (
    tester,
  ) async {
    await tester.pumpWidget(CatalogGalleryApp(samplesDir: samplesDir, fs: fs));
    await tester.pumpAndSettle();

    expect(find.text('Catalog Gallery'), findsOneWidget);
    expect(find.text('Samples'), findsOneWidget);
  });

  group('Sample Rendering Tests', () {
    for (final file in files) {
      final String fileName = fs.path.basename(file.path);
      testWidgets('Render sample: $fileName', (WidgetTester tester) async {
        genUiLogger.info('Starting test for $fileName');

        // Start the app with specific samples directory
        await tester.pumpWidget(
          CatalogGalleryApp(key: UniqueKey(), samplesDir: samplesDir, fs: fs),
        );
        await tester.pumpAndSettle();

        // Switch to the Samples tab.
        await tester.tap(find.text('Samples'));
        await tester.pumpAndSettle();

        // Find the sample in the list.
        final String displayName = fs.path.basenameWithoutExtension(file.path);

        final Finder sampleItemFinder = find.widgetWithText(
          ListTile,
          displayName,
        );

        // Scroll to the item if needed.
        // The samples list is the first ListView in the hierarchy.
        await tester.scrollUntilVisible(
          sampleItemFinder,
          500,
          scrollable: find
              .descendant(
                of: find.byType(ListView).first,
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();

        expect(
          sampleItemFinder,
          findsOneWidget,
          reason: 'Sample $displayName should be visible in the list',
        );

        // Tap the sample
        await tester.tap(sampleItemFinder);
        await tester.pumpAndSettle();

        // Verify content
        final String content = file.readAsStringSync();
        final List<String> expectedTexts = _extractExpectedText(content);
        final List<String> expectedIds = _extractComponentIds(content);

        // Verify text content
        for (final text in expectedTexts) {
          if (find.text(text).evaluate().isEmpty) {
            // Optional warning logging
          }
        }

        final Set<String> ignoredIds = _ignoredIds[fileName] ?? {};
        for (final id in expectedIds) {
          if (ignoredIds.contains(id)) {
            continue;
          }
          if (find
              .byKey(ValueKey(id), skipOffstage: false)
              .evaluate()
              .isEmpty) {
            fail('Expected component with ID "$id" to be in the widget tree.');
          }
        }
      });
    }
  });
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
