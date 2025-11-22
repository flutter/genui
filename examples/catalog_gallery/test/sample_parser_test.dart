// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:catalog_gallery/sample_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

void main() {
  test('SampleParser parses valid sample string', () async {
    const sampleContent = '''
name: Test Sample
description: A test description
---
{"surfaceUpdate": {"surfaceId": "default", "components": [{"id": "text1", "props": {"component": "Text", "text": {"literalString": "Hello"}}}]}}
{"createSurface": {"surfaceId": "default"}}
''';

    final Sample sample = SampleParser.parseString(sampleContent);

    expect(sample.name, 'Test Sample');
    expect(sample.description, 'A test description');

    final List<A2uiMessage> messages = await sample.messages.toList();
    expect(messages.length, 2);
    expect(messages.first, isA<SurfaceUpdate>());
    expect(messages.last, isA<CreateSurface>());

    final update = messages.first as SurfaceUpdate;
    expect(update.surfaceId, 'default');
    expect(update.components.length, 1);
    expect(update.components.first.type, 'Text');

    final begin = messages.last as CreateSurface;
    expect(begin.surfaceId, 'default');
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
