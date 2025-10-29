// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_genui_google_generative_ai/flutter_genui_google_generative_ai.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GoogleGenerativeAiContentGenerator', () {
    test('constructor creates instance with required parameters', () {
      final catalog = Catalog(<CatalogItem>[]);

      final generator = GoogleGenerativeAiContentGenerator(
        catalog: catalog,
        apiKey: 'test-api-key',
      );

      expect(generator, isNotNull);
      expect(generator.catalog, catalog);
      expect(generator.modelName, 'models/gemini-2.5-flash');
      expect(generator.outputToolName, 'provideFinalOutput');
    });

    test('constructor accepts custom model name', () {
      final catalog = Catalog(<CatalogItem>[]);

      final generator = GoogleGenerativeAiContentGenerator(
        catalog: catalog,
        modelName: 'models/gemini-2.5-pro',
        apiKey: 'test-api-key',
      );

      expect(generator.modelName, 'models/gemini-2.5-pro');
    });

    test('constructor accepts custom output tool name', () {
      final catalog = Catalog(<CatalogItem>[]);

      final generator = GoogleGenerativeAiContentGenerator(
        catalog: catalog,
        outputToolName: 'customOutput',
        apiKey: 'test-api-key',
      );

      expect(generator.outputToolName, 'customOutput');
    });

    test('constructor accepts system instruction', () {
      final catalog = Catalog(<CatalogItem>[]);

      final generator = GoogleGenerativeAiContentGenerator(
        catalog: catalog,
        systemInstruction: 'You are a helpful assistant',
        apiKey: 'test-api-key',
      );

      expect(generator.systemInstruction, 'You are a helpful assistant');
    });

    test('constructor accepts additional tools', () {
      final catalog = Catalog(<CatalogItem>[]);
      final tool = DynamicAiTool<Map<String, Object?>>(
        name: 'testTool',
        description: 'A test tool',
        invokeFunction: (args) async => {},
      );

      final generator = GoogleGenerativeAiContentGenerator(
        catalog: catalog,
        additionalTools: [tool],
        apiKey: 'test-api-key',
      );

      expect(generator.additionalTools, hasLength(1));
      expect(generator.additionalTools.first.name, 'testTool');
    });

    test('streams are accessible', () {
      final catalog = Catalog(<CatalogItem>[]);

      final generator = GoogleGenerativeAiContentGenerator(
        catalog: catalog,
        apiKey: 'test-api-key',
      );

      expect(generator.a2uiMessageStream, isNotNull);
      expect(generator.textResponseStream, isNotNull);
      expect(generator.errorStream, isNotNull);
      expect(generator.isProcessing, isNotNull);
    });

    test('isProcessing starts as false', () {
      final catalog = Catalog(<CatalogItem>[]);

      final generator = GoogleGenerativeAiContentGenerator(
        catalog: catalog,
        apiKey: 'test-api-key',
      );

      expect(generator.isProcessing.value, isFalse);
    });

    test('dispose closes all streams', () {
      final catalog = Catalog(<CatalogItem>[]);

      final generator = GoogleGenerativeAiContentGenerator(
        catalog: catalog,
        apiKey: 'test-api-key',
      );

      // Should not throw
      expect(() => generator.dispose(), returnsNormally);
    });

    test('token usage starts at zero', () {
      final catalog = Catalog(<CatalogItem>[]);

      final generator = GoogleGenerativeAiContentGenerator(
        catalog: catalog,
        apiKey: 'test-api-key',
      );

      expect(generator.inputTokenUsage, 0);
      expect(generator.outputTokenUsage, 0);
    });
  });
}
