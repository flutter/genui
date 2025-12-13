// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart' as genui;
import 'package:genui_dartantic/genui_dartantic.dart';

void main() {
  group('DartanticContentGenerator', () {
    // Use the ollama provider for testing - it doesn't require API keys
    // Note: These tests only verify object construction, not actual AI calls
    late dartantic.OllamaProvider testProvider;

    setUp(() {
      testProvider = dartantic.OllamaProvider();
    });

    group('construction', () {
      test('creates generator with required parameters', () {
        final generator = DartanticContentGenerator(
          provider: testProvider,
          catalog: const genui.Catalog({}),
        );

        expect(generator, isNotNull);
        expect(generator.catalog, isNotNull);
        expect(generator.isProcessing.value, isFalse);

        generator.dispose();
      });

      test('creates generator with all optional parameters', () {
        final generator = DartanticContentGenerator(
          provider: testProvider,
          catalog: const genui.Catalog({}),
          systemInstruction: 'You are a helpful assistant.',
          additionalTools: [
            genui.DynamicAiTool<Map<String, Object?>>(
              name: 'testTool',
              description: 'A test tool',
              invokeFunction: (args) async => {'result': 'ok'},
            ),
          ],
        );

        expect(generator, isNotNull);
        expect(generator.systemInstruction, 'You are a helpful assistant.');

        generator.dispose();
      });
    });

    group('streams', () {
      test('provides a2uiMessageStream', () {
        final generator = DartanticContentGenerator(
          provider: testProvider,
          catalog: const genui.Catalog({}),
        );

        expect(generator.a2uiMessageStream, isA<Stream<genui.A2uiMessage>>());

        generator.dispose();
      });

      test('provides textResponseStream', () {
        final generator = DartanticContentGenerator(
          provider: testProvider,
          catalog: const genui.Catalog({}),
        );

        expect(generator.textResponseStream, isA<Stream<String>>());

        generator.dispose();
      });

      test('provides errorStream', () {
        final generator = DartanticContentGenerator(
          provider: testProvider,
          catalog: const genui.Catalog({}),
        );

        expect(
          generator.errorStream,
          isA<Stream<genui.ContentGeneratorError>>(),
        );

        generator.dispose();
      });
    });

    group('isProcessing', () {
      test('initially false', () {
        final generator = DartanticContentGenerator(
          provider: testProvider,
          catalog: const genui.Catalog({}),
        );

        expect(generator.isProcessing.value, isFalse);

        generator.dispose();
      });
    });
  });
}
