// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart' as fai;
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_genui/src/ai_client/gemini_schema_adapter.dart';
import 'package:logging/logging.dart';

class GeminiClient {
  GeminiClient({required this.tools, required String systemInstruction}) {
    final functionDeclarations = <fai.FunctionDeclaration>[];
    final adapter = GeminiSchemaAdapter();
    for (final tool in tools) {
      fai.Schema? adaptedParameters;
      if (tool.parameters != null) {
        final result = adapter.adapt(tool.parameters!);
        if (result.errors.isNotEmpty) {
          _logger.warning(
            'Errors adapting parameters for tool ${tool.name}: '
            '${result.errors.join('\n')}',
          );
        }
        adaptedParameters = result.schema;
      }
      final parameters = adaptedParameters?.properties;
      functionDeclarations.add(
        fai.FunctionDeclaration(
          tool.name,
          tool.description,
          parameters: parameters ?? const {},
        ),
      );
    }

    _logger.info(
      'Registered tools: ${functionDeclarations.map((d) => d.name).join(', ')}',
    );

    _model = fai.FirebaseAI.googleAI().generativeModel(
      model: 'gemini-pro',
      systemInstruction: fai.Content.system(systemInstruction),
      tools: [fai.Tool.functionDeclarations(functionDeclarations)],
    );
  }

  late final fai.GenerativeModel _model;
  final List<AiTool> tools;
  final _logger = Logger('GeminiClient');

  Future<fai.GenerateContentResponse> generate(
    Iterable<fai.Content> history,
  ) async {
    final mutableHistory = List.of(history);
    var toolUsageCycle = 0;
    const maxToolUsageCycles = 10;

    while (toolUsageCycle < maxToolUsageCycles) {
      toolUsageCycle++;

      final concatenatedContents = mutableHistory
          .map((c) => const JsonEncoder.withIndent('  ').convert(c.toJson()))
          .join('\n');

      _logger.info(
        '****** Performing Inference ******\n$concatenatedContents\n'
        'With functions:\n'
        '  ${tools.map((t) => t.name).join(', ')}',
      );

      final inferenceStartTime = DateTime.now();
      final response = await _model.generateContent(mutableHistory);
      final elapsed = DateTime.now().difference(inferenceStartTime);

      final candidate = response.candidates.first;
      final content = candidate.content;
      mutableHistory.add(content);

      _logger.info(
        '****** Completed Inference ******\n'
        'Latency = ${elapsed.inMilliseconds}ms\n'
        'Output tokens = ${response.usageMetadata?.candidatesTokenCount ?? 0}\n'
        'Prompt tokens = ${response.usageMetadata?.promptTokenCount ?? 0}\n'
        '${const JsonEncoder.withIndent('  ').convert(content.toJson())}',
      );

      final functionCalls = content.parts
          .whereType<fai.FunctionCall>()
          .toList();

      if (functionCalls.isEmpty) {
        return response;
      }

      final functionResponses = <fai.FunctionResponse>[];
      for (final call in functionCalls) {
        final tool = tools.firstWhere((t) => t.name == call.name);
        final result = await tool.invoke(call.args);
        functionResponses.add(fai.FunctionResponse(call.name, result));
      }

      mutableHistory.add(fai.Content.functionResponses(functionResponses));
    }

    throw Exception('Max tool usage cycles reached');
  }
}
