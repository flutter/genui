// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: specify_nonobvious_local_variable_types

import 'dart:async';

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;
import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';
import 'package:json_schema/json_schema.dart';

import 'dartantic_content_converter.dart';
import 'dartantic_schema_adapter.dart';

/// A [ContentGenerator] that uses Dartantic AI to generate content.
///
/// This generator utilizes a [dartantic.Provider] to interact with various
/// AI providers (OpenAI, Anthropic, Google, Mistral, Cohere, Ollama) through
/// the dartantic_ai package.
///
/// The generator creates tools from the GenUI catalog and any additional tools
/// provided, then uses dartantic's built-in tool calling and structured output
/// capabilities to generate UI content.
///
/// This implementation is **stateless** - it does not maintain internal
/// conversation history. Instead, it uses the history provided by
/// [GenUiConversation] via the [sendRequest] method's `history` parameter.
class DartanticContentGenerator implements ContentGenerator {
  /// Creates a [DartanticContentGenerator] instance.
  ///
  /// - [provider]: The dartantic AI provider to use (e.g., `Providers.google`,
  ///   `Providers.openai`, `Providers.anthropic`).
  /// - [catalog]: The catalog of UI components available to the AI.
  /// - [systemInstruction]: Optional system instruction for the AI model.

  /// - [additionalTools]: Additional GenUI [AiTool] instances to make
  ///   available.
  DartanticContentGenerator({
    required dartantic.Provider provider,
    required this.catalog,
    this.systemInstruction,
    this.modelName,
    List<AiTool<JsonMap>> additionalTools = const [],
  }) {
    // Build GenUI tools
    final genUiTools = <AiTool<JsonMap>>[
      SurfaceUpdateTool(
        handleMessage: _a2uiMessageController.add,
        catalog: catalog,
      ),
      BeginRenderingTool(handleMessage: _a2uiMessageController.add),
      DeleteSurfaceTool(handleMessage: _a2uiMessageController.add),
      ...additionalTools,
    ];

    // Convert all tools to dartantic format
    final List<dartantic.Tool> dartanticTools = _convertTools(genUiTools);

    // Create agent with converted tools
    _agent = dartantic.Agent.forProvider(
      provider,
      chatModelName: modelName,
      tools: dartanticTools,
    );

    // Create additional system instructions to augment what the client sends
    _extraInstructions =
        '''
<tools>
${dartanticTools.map((tool) => tool.toJson()).join('\n\n')}
</tools>

<output_schema>
${_outputSchema.toJson()}
</output_schema>
''';

    genUiLogger.info('Extra system instructions: $_extraInstructions');
  }

  /// The catalog of UI components available to the AI.
  final Catalog catalog;

  /// The system instruction to use for the AI model.
  final String? systemInstruction;

  /// The model name to use.
  final String? modelName;

  /// The configuration of the GenUI system.

  late final dartantic.Agent _agent;
  final DartanticContentConverter _converter = DartanticContentConverter();

  final _a2uiMessageController = StreamController<A2uiMessage>.broadcast();
  final _textResponseController = StreamController<String>.broadcast();
  final _errorController = StreamController<ContentGeneratorError>.broadcast();
  final _isProcessing = ValueNotifier<bool>(false);
  late final String _extraInstructions;

  /// Structured output schema: a simple object with a required string response.
  static final JsonSchema _outputSchema = JsonSchema.create({
    'type': 'object',
    'properties': {
      'response': {
        'type': 'string',
        'description': 'The text response to the user.',
      },
    },
    'required': ['response'],
  });

  @override
  Stream<A2uiMessage> get a2uiMessageStream => _a2uiMessageController.stream;

  @override
  Stream<String> get textResponseStream => _textResponseController.stream;

  @override
  Stream<ContentGeneratorError> get errorStream => _errorController.stream;

  @override
  ValueListenable<bool> get isProcessing => _isProcessing;

  @override
  void dispose() {
    _a2uiMessageController.close();
    _textResponseController.close();
    _errorController.close();
    _isProcessing.dispose();
  }

  @override
  Future<void> sendRequest(
    ChatMessage message, {
    Iterable<ChatMessage>? history,
    A2UiClientCapabilities? clientCapabilities,
  }) async {
    _isProcessing.value = true;
    try {
      // Convert GenUI history to dartantic ChatMessage list
      final List<dartantic.ChatMessage> dartanticHistory = _converter.toHistory(
        history,
        systemInstruction: '$systemInstruction\n\n$_extraInstructions',
      );

      // Convert the current GenUI message into prompt text plus parts so we
      // preserve text, data, and tool content.
      final ({String prompt, List<dartantic.Part> parts}) promptAndParts =
          _converter.toPromptAndParts(message);

      // We should never have tool calls or results in request message.
      assert(promptAndParts.parts.every((part) => part is! dartantic.ToolPart));

      genUiLogger.info(
        'Sending request to Dartantic: "${promptAndParts.prompt}"',
      );
      genUiLogger.fine('History contains ${dartanticHistory.length} messages');

      // Use Agent.sendFor with structured output so the model returns a single
      // response string instead of dumping JSON/tool content as text.
      final dartantic.ChatResult<Map<String, dynamic>> result = await _agent
          .sendFor<Map<String, dynamic>>(
            promptAndParts.prompt,
            outputSchema: _outputSchema,
            history: dartanticHistory,
            attachments: promptAndParts.parts,
          );

      final String responseText = _parseResponse(result.output);

      _textResponseController.add(responseText);
      genUiLogger.info('Received response from Dartantic: $responseText');
    } catch (e, st) {
      genUiLogger.severe('Error generating content', e, st);
      _errorController.add(ContentGeneratorError(e, st));
    } finally {
      _isProcessing.value = false;
    }
  }

  /// Converts GenUI [AiTool] instances to dartantic [dartantic.Tool] instances.
  List<dartantic.Tool> _convertTools(List<AiTool<JsonMap>> tools) => tools
      .map(
        (aiTool) => dartantic.Tool(
          name: aiTool.name,
          description: aiTool.description,
          inputSchema: adaptSchema(aiTool.parameters),
          onCall: (Map<String, dynamic> args) async {
            genUiLogger.fine('Invoking tool: ${aiTool.name} with args: $args');
            final JsonMap result = await aiTool.invoke(args);
            genUiLogger.fine('Tool ${aiTool.name} returned: $result');
            return result;
          },
        ),
      )
      .toList();

  /// Validates and extracts the response text from the structured output.
  String _parseResponse(Map<String, dynamic> output) {
    final Object? responseValue = output['response'];
    if (responseValue is! String) {
      throw StateError(
        'Dartantic returned a non-string response: $responseValue',
      );
    }
    final String responseText = responseValue.trim();
    if (responseText.isEmpty) {
      throw StateError('Dartantic returned an empty response string.');
    }
    return responseText;
  }
}
