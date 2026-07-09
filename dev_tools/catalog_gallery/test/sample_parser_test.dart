// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_core/a2ui_core.dart' as core;
import 'package:catalog_gallery/sample_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SampleParser parses valid sample string', () async {
    const sampleContent = '''
name: Test Sample
description: A test description
---
{"version": "v1.0", "updateComponents": {"surfaceId": "default", "components": [{"id": "text1", "component": "Text", "text": "Hello"}]}}
{"version": "v1.0", "createSurface": {"surfaceId": "default", "catalogId": "https://a2ui.org/specification/v1_0/catalogs/basic/catalog.json"}}
''';

    final Sample sample = SampleParser.parseString(sampleContent);

    expect(sample.name, 'Test Sample');
    expect(sample.description, 'A test description');

    final List<core.A2uiMessage> messages = await sample.messages.toList();
    expect(messages.length, 2);
    expect(messages.first, isA<core.UpdateComponentsMessage>());
    expect(messages.last, isA<core.CreateSurfaceMessage>());

    final update = messages.first as core.UpdateComponentsMessage;
    expect(update.surfaceId, 'default');
    expect(update.components.length, 1);
    expect(update.components.first['component'], 'Text');

    final createSurface = messages.last as core.CreateSurfaceMessage;
    expect(createSurface.surfaceId, 'default');
  });

  test(
    'SampleParser parses sample with frontmatter (leading dashes)',
    () async {
      const sampleContent = '''
---
name: Frontmatter Sample
description: A description
---
{"version": "v1.0", "createSurface": {"surfaceId": "default", "catalogId": "test"}}
''';
      final Sample sample = SampleParser.parseString(sampleContent);
      expect(sample.name, 'Frontmatter Sample');
      final List<core.A2uiMessage> messages = await sample.messages.toList();
      expect(messages.length, 1);
    },
  );

  test('SampleParser parses sample with empty header', () async {
    const sampleContent = '''
---
---
{"version": "v1.0", "createSurface": {"surfaceId": "default", "catalogId": "test"}}
''';
    final Sample sample = SampleParser.parseString(sampleContent);
    expect(sample.name, 'Untitled Sample');
    final List<core.A2uiMessage> messages = await sample.messages.toList();
    expect(messages.length, 1);
  });

  test('SampleParser throws on missing separator', () {
    const sampleContent = '''
name: Invalid Sample
No separator here
''';

    expect(
      () => SampleParser.parseString(sampleContent),
      throwsFormatException,
    );
  });
}
