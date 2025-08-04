// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_genui/src/ai_client/tools.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiTool', () {
    test('toFunctionDeclarations returns correct declarations', () {
      final tool = DynamicAiTool<Map<String, Object?>>(
        name: 'testTool',
        description: 'A test tool.',
        parameters: Schema.object(properties: {'param1': Schema.string()}),
        invokeFunction: (args) async => {},
      );

      final declarations = tool.toFunctionDeclarations();
      expect(declarations.length, 1);
      final declaration = declarations.first;
      expect(declaration.name, 'testTool');
      expect(declaration.description, 'A test tool.');
    });

    test(
      'toFunctionDeclarations returns two declarations when prefix is used',
      () {
        final tool = DynamicAiTool<Map<String, Object?>>(
          name: 'testTool',
          prefix: 'prefix',
          description: 'A test tool.',
          parameters: Schema.object(properties: {'param1': Schema.string()}),
          invokeFunction: (args) async => {},
        );

        final declarations = tool.toFunctionDeclarations();
        expect(declarations.length, 2);
        expect(declarations[0].name, 'testTool');
        expect(declarations[1].name, 'prefix.testTool');
      },
    );

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
