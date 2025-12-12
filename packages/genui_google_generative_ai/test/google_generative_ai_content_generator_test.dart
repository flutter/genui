// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart' as genui;
import 'package:genui_google_generative_ai/genui_google_generative_ai.dart';
import 'package:google_cloud_ai_generativelanguage_v1beta/generativelanguage.dart'
    as google_ai;
import 'package:google_cloud_protobuf/protobuf.dart' as protobuf;
import 'package:json_schema_builder/json_schema_builder.dart' as dsb;

void main() {
  group('GoogleGenerativeAiContentGenerator', () {
    test('constructor creates instance with required parameters', () {
      final catalog = const genui.Catalog(<genui.CatalogItem>[]);

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
      final catalog = const genui.Catalog(<genui.CatalogItem>[]);

      final generator = GoogleGenerativeAiContentGenerator(
        catalog: catalog,
        modelName: 'models/gemini-2.5-pro',
        apiKey: 'test-api-key',
      );

      expect(generator.modelName, 'models/gemini-2.5-pro');
    });

    test('constructor accepts custom output tool name', () {
      final catalog = const genui.Catalog(<genui.CatalogItem>[]);

      final generator = GoogleGenerativeAiContentGenerator(
        catalog: catalog,
        outputToolName: 'customOutput',
        apiKey: 'test-api-key',
      );

      expect(generator.outputToolName, 'customOutput');
    });

    test('constructor accepts system instruction', () {
      final catalog = const genui.Catalog(<genui.CatalogItem>[]);

      final generator = GoogleGenerativeAiContentGenerator(
        catalog: catalog,
        systemInstruction: 'You are a helpful assistant',
        apiKey: 'test-api-key',
      );

      expect(generator.systemInstruction, 'You are a helpful assistant');
    });

    test('constructor accepts additional tools', () {
      final catalog = const genui.Catalog(<genui.CatalogItem>[]);
      final tool = genui.DynamicAiTool<Map<String, Object?>>(
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
      final catalog = const genui.Catalog(<genui.CatalogItem>[]);

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
      final catalog = const genui.Catalog(<genui.CatalogItem>[]);

      final generator = GoogleGenerativeAiContentGenerator(
        catalog: catalog,
        apiKey: 'test-api-key',
      );

      expect(generator.isProcessing.value, isFalse);
    });

    test('dispose closes all streams', () {
      final catalog = const genui.Catalog(<genui.CatalogItem>[]);

      final generator = GoogleGenerativeAiContentGenerator(
        catalog: catalog,
        apiKey: 'test-api-key',
      );

      // Should not throw
      expect(generator.dispose, returnsNormally);
    });

    test('token usage starts at zero', () {
      final catalog = const genui.Catalog(<genui.CatalogItem>[]);

      final generator = GoogleGenerativeAiContentGenerator(
        catalog: catalog,
        apiKey: 'test-api-key',
      );

      expect(generator.inputTokenUsage, 0);
      expect(generator.outputTokenUsage, 0);
    });

    test('isProcessing is true during request', () async {
      final generator = GoogleGenerativeAiContentGenerator(
        catalog: const genui.Catalog({}),
        serviceFactory: ({required configuration}) {
          return FakeGoogleGenerativeService([
            google_ai.GenerateContentResponse(
              candidates: [
                google_ai.Candidate(
                  content: google_ai.Content(
                    role: 'model',
                    parts: [
                      google_ai.Part(
                        functionCall: google_ai.FunctionCall(
                          id: '1',
                          name: 'provideFinalOutput',
                          args: protobuf.Struct.fromJson({
                            'output': {'response': 'Hello'},
                          }),
                        ),
                      ),
                    ],
                  ),
                  finishReason: google_ai.Candidate_FinishReason.stop,
                ),
              ],
            ),
          ]);
        },
      );

      expect(generator.isProcessing.value, isFalse);
      final future = generator.sendRequest(
        genui.UserMessage([const genui.TextPart('Hi')]),
      );
      expect(generator.isProcessing.value, isTrue);
      await future;
      expect(generator.isProcessing.value, isFalse);
    });

    test('can call a tool and return a result', () async {
      final generator = GoogleGenerativeAiContentGenerator(
        catalog: const genui.Catalog({}),
        additionalTools: [
          genui.DynamicAiTool<Map<String, Object?>>(
            name: 'testTool',
            description: 'A test tool',
            parameters: dsb.Schema.object(),
            invokeFunction: (args) async => {'result': 'tool result'},
          ),
        ],
        serviceFactory: ({required configuration}) {
          return FakeGoogleGenerativeService([
            google_ai.GenerateContentResponse(
              candidates: [
                google_ai.Candidate(
                  content: google_ai.Content(
                    role: 'model',
                    parts: [
                      google_ai.Part(
                        functionCall: google_ai.FunctionCall(
                          id: '1',
                          name: 'testTool',
                          args: protobuf.Struct.fromJson(<String, dynamic>{}),
                        ),
                      ),
                    ],
                  ),
                  finishReason: google_ai.Candidate_FinishReason.stop,
                ),
              ],
            ),
            google_ai.GenerateContentResponse(
              candidates: [
                google_ai.Candidate(
                  content: google_ai.Content(
                    role: 'model',
                    parts: [
                      google_ai.Part(
                        functionCall: google_ai.FunctionCall(
                          id: '2',
                          name: 'provideFinalOutput',
                          args: protobuf.Struct.fromJson(<String, dynamic>{
                            'output': {'response': 'Tool called'},
                          }),
                        ),
                      ),
                    ],
                  ),
                  finishReason: google_ai.Candidate_FinishReason.stop,
                ),
              ],
            ),
          ]);
        },
      );

      final hi = genui.UserMessage([const genui.TextPart('Hi')]);
      final completer = Completer<String>();
      unawaited(generator.textResponseStream.first.then(completer.complete));
      await generator.sendRequest(hi);
      final response = await completer.future;
      expect(response, 'Tool called');
    });

    test('returns a simple text response', () async {
      final generator = GoogleGenerativeAiContentGenerator(
        catalog: const genui.Catalog({}),
        serviceFactory: ({required configuration}) {
          return FakeGoogleGenerativeService([
            google_ai.GenerateContentResponse(
              candidates: [
                google_ai.Candidate(
                  content: google_ai.Content(
                    role: 'model',
                    parts: [
                      google_ai.Part(
                        functionCall: google_ai.FunctionCall(
                          id: '1',
                          name: 'provideFinalOutput',
                          args: protobuf.Struct.fromJson({
                            'output': {'response': 'Hello'},
                          }),
                        ),
                      ),
                    ],
                  ),
                  finishReason: google_ai.Candidate_FinishReason.stop,
                ),
              ],
            ),
          ]);
        },
      );

      final hi = genui.UserMessage([const genui.TextPart('Hi')]);
      final completer = Completer<String>();
      unawaited(generator.textResponseStream.first.then(completer.complete));
      await generator.sendRequest(hi);
      final response = await completer.future;
      expect(response, 'Hello');
    });
  });
}

class FakeGoogleGenerativeService implements GoogleGenerativeServiceInterface {
  FakeGoogleGenerativeService(this.responses);

  final List<google_ai.GenerateContentResponse> responses;
  int callCount = 0;

  @override
  Future<google_ai.GenerateContentResponse> generateContent(
    google_ai.GenerateContentRequest request,
  ) {
    return Future.delayed(Duration.zero, () => responses[callCount++]);
  }

  @override
  void close() {
    // No-op for testing
  }
}
