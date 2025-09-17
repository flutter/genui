// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter_genui/src/model/tools.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiTool', () {
    test('fullName returns correct name', () {
      final tool = DynamicAiTool<Map<String, Object?>>(
        name: 'testTool',
        description: 'A test tool.',
        invokeFunction: (args) async => {},
      );
      expect(tool.fullName, 'testTool');

      final toolWithPrefix = DynamicAiTool<Map<String, Object?>>(
        name: 'testTool',
        prefix: 'prefix',
        description: 'A test tool.',
        invokeFunction: (args) async => {},
      );
      expect(toolWithPrefix.fullName, 'prefix.testTool');
    });
  });

  group('DynamicAiTool', () {
    test('invoke calls invokeFunction', () async {
      var called = false;
      final tool = DynamicAiTool<Map<String, Object?>>(
        name: 'testTool',
        description: 'A test tool.',
        parameters: S.object(properties: {}),
        invokeFunction: (args) async {
          called = true;
          return {};
        },
      );

      await tool.invoke({});
      expect(called, isTrue);
    });
  });
}
