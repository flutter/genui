// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;
import 'package:dartantic_interface/dartantic_interface.dart' as di;
import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';
import 'package:json_schema/json_schema.dart';

import 'dartantic_content_converter.dart';
import 'dartantic_schema_adapter.dart';

/// A [ContentGenerator] that uses Dartantic AI to generate content.
///
/// This generator utilizes a [di.Provider] to interact with various
/// AI providers (OpenAI, Anthropic, Google, Mistral, Cohere, Ollama) through
/// the dartantic_ai package.
///
/// The generator creates tools from the GenUI catalog and any additional tools
/// provided, then uses dartantic's built-in tool calling and structured output
/// capabilities to generate UI content.
class DartanticContentGenerator implements ContentGenerator {
  /// Creates a [DartanticContentGenerator] instance.
  ///
  /// - [provider]: The dartantic AI provider to use (e.g., `Providers.google`,
  ///   `Providers.openai`, `Providers.anthropic`).
  /// - [catalog]: The catalog of UI components available to the AI.
  /// - [systemInstruction]: Optional system instruction for the AI model.
  /// - [configuration]: Configuration for allowed actions (create/update/delete).
  /// - [additionalTools]: Additional GenUI [AiTool] instances to make available.
  DartanticContentGenerator({
    required di.Provider provider,
    required this.catalog,
    this.systemInstruction,
    this.configuration = const GenUiConfiguration(),
    List<AiTool<JsonMap>> additionalTools = const [],
  }) {
    // Build GenUI tools based on configuration
    final genUiTools = <AiTool<JsonMap>>[
      if (configuration.actions.allowCreate ||
          configuration.actions.allowUpdate) ...[
        SurfaceUpdateTool(
          handleMessage: _a2uiMessageController.add,
          catalog: catalog,
          configuration: configuration,
        ),
        BeginRenderingTool(handleMessage: _a2uiMessageController.add),
      ],
      if (configuration.actions.allowDelete)
        DeleteSurfaceTool(handleMessage: _a2uiMessageController.add),
      ...additionalTools,
    ];

    // Convert all tools to dartantic format
    final dartanticTools = _convertTools(genUiTools);

    // Create agent with converted tools
    final agent = dartantic.Agent.forProvider(provider, tools: dartanticTools);

    // Create chat with system instruction as initial history
    _chat = dartantic.Chat(
      agent,
      history: [
        if (systemInstruction != null)
          di.ChatMessage.system(systemInstruction!),
      ],
    );
  }

  /// The catalog of UI components available to the AI.
  final Catalog catalog;

  /// The system instruction to use for the AI model.
  final String? systemInstruction;

  /// The configuration of the GenUI system.
  final GenUiConfiguration configuration;

  late final dartantic.Chat _chat;
  final _converter = DartanticContentConverter();

  final _a2uiMessageController = StreamController<A2uiMessage>.broadcast();
  final _textResponseController = StreamController<String>.broadcast();
  final _errorController = StreamController<ContentGeneratorError>.broadcast();
  final _isProcessing = ValueNotifier<bool>(false);

  /// The output schema for structured responses.
  ///
  /// This matches the schema used by FirebaseAiContentGenerator to ensure
  /// consistent behavior.
  static final _outputSchema = JsonSchema.create({
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
  }) async {
    _isProcessing.value = true;
    try {
      if (history != null && history.isNotEmpty) {
        genUiLogger.warning(
          'DartanticContentGenerator is stateful and ignores history parameter.',
        );
      }

      // Convert GenUI message to prompt text
      final promptText = _converter.toPromptText(message);

      genUiLogger.info('Sending request to Dartantic: "$promptText"');

      // Use sendFor with output schema for structured response
      // Tool calls will be executed automatically by dartantic
      final result = await _chat.sendFor<Map<String, dynamic>>(
        promptText,
        outputSchema: _outputSchema,
      );

      genUiLogger.info('Received response from Dartantic');

      // Extract the response text from structured output
      if (result.output is Map && result.output.containsKey('response')) {
        final responseText = result.output['response'] as String;
        if (responseText.isNotEmpty) {
          _textResponseController.add(responseText);
        }
      } else if (result.output != null) {
        // Fallback: convert output to string
        _textResponseController.add(result.output.toString());
      }
    } catch (e, st) {
      genUiLogger.severe('Error generating content', e, st);
      _errorController.add(ContentGeneratorError(e, st));
    } finally {
      _isProcessing.value = false;
    }
  }

  /// Converts GenUI [AiTool] instances to dartantic [di.Tool] instances.
  List<di.Tool> _convertTools(List<AiTool<JsonMap>> tools) {
    final adapter = DartanticSchemaAdapter();
    return tools.map((aiTool) {
      final schemaResult = adapter.adapt(aiTool.parameters);
      if (schemaResult.errors.isNotEmpty) {
        genUiLogger.warning(
          'Errors adapting parameters for tool ${aiTool.name}: '
          '${schemaResult.errors.join('\n')}',
        );
      }
      return di.Tool(
        name: aiTool.name,
        description: aiTool.description,
        inputSchema: schemaResult.schema,
        onCall: (Map<String, dynamic> args) async {
          genUiLogger.fine('Invoking tool: ${aiTool.name} with args: $args');
          final result = await aiTool.invoke(args);
          genUiLogger.fine('Tool ${aiTool.name} returned: $result');
          return result;
        },
      );
    }).toList();
  }
}
