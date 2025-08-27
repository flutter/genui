// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

import '../model/chat_message.dart' as msg;
import '../model/tools.dart';
import '../primitives/logging.dart';
import '../primitives/simple_items.dart';
import 'ai_client.dart';
import 'gemini_content_converter.dart';
import 'gemini_generative_model.dart';
import 'gemini_schema_adapter.dart';

/// A factory for creating a [GeminiGenerativeModelInterface].
///
/// This is used to allow for custom model creation, for example, for testing.
typedef GenerativeModelFactory =
    GeminiGenerativeModelInterface Function({
      required FirebaseAiClient configuration,
      Content? systemInstruction,
      List<Tool>? tools,
      ToolConfig? toolConfig,
    });

/// An enum for the available Gemini models.
enum GeminiModelType {
  /// The Gemini 2.5 Flash model.
  flash('gemini-2.5-flash', 'Gemini 2.5 Flash'),

  /// The Gemini 2.5 Pro model.
  pro('gemini-2.5-pro', 'Gemini 2.5 Pro');

  /// Creates a [GeminiModelType] with the given [modelName] and [displayName].
  const GeminiModelType(this.modelName, this.displayName);

  /// The name of the model as known by the Gemini API.
  final String modelName;

  /// The human-readable name of the model.
  final String displayName;
}

/// A class that represents a Gemini model.
class GeminiModel extends AiModel {
  /// Creates a new instance of [GeminiModel] as a specific [type].
  GeminiModel(this.type);

  /// The type of the model.
  final GeminiModelType type;

  @override
  String get displayName => type.displayName;
}

/// A basic implementation of [AiClient] for accessing a Gemini model.
///
/// This class encapsulates settings for interacting with a generative AI model,
/// including model selection, API keys, and tool
/// configurations. It provides a [generateText] method to interact with the
/// AI model, supporting structured output and tool usage.
class FirebaseAiClient implements AiClient {
  /// Creates an [FirebaseAiClient] instance with specified configurations.
  ///
  /// - [model]: The identifier of the generative AI model to use.
  /// - [modelCreator]: A factory function to create the [GenerativeModel].
  /// - [maxConcurrentJobs]: Intended for managing concurrent AI operations,
  ///   though not directly enforced by [generateText] itself.
  /// - [tools]: A list of default [AiTool]s available to the AI.
  FirebaseAiClient({
    GeminiModelType model = GeminiModelType.flash,
    this.systemInstruction,
    this.modelCreator = defaultGenerativeModelFactory,
    this.maxConcurrentJobs = 20,
    this.tools = const <AiTool>[],
  }) : _model = ValueNotifier(GeminiModel(model)) {
    final duplicateToolNames = tools.map((t) => t.name).toSet();
    if (duplicateToolNames.length != tools.length) {
      final duplicateTools = tools.where((t) {
        return tools.where((other) => other.name == t.name).length > 1;
      });
      throw AiClientException(
        'Duplicate tool(s) '
        '${duplicateTools.map<String>((t) => t.name).toSet().join(', ')} '
        'registered. Tool names must be unique.',
      );
    }
  }

  /// The system instruction to use for the AI model.
  final String? systemInstruction;

  /// The name of the Gemini model to use.
  ///
  /// This identifier specifies which version or type of the generative AI model
  /// will be invoked for content generation.
  ///
  /// Defaults to 'gemini-2.5-flash'.
  final ValueNotifier<GeminiModel> _model;

  @override
  ValueListenable<AiModel> get model => _model;

  @override
  List<AiModel> get models =>
      GeminiModelType.values.map(GeminiModel.new).toList();

  /// The maximum number of concurrent jobs to run.
  ///
  /// This property is intended for systems that might manage multiple
  /// [FirebaseAiClient] operations or other concurrent tasks. The
  /// [generateText] method itself is a single asynchronous operation and
  /// does not directly enforce this limit.
  ///
  /// Defaults to 20.
  final int maxConcurrentJobs;

  /// A function to use for creating the model itself.
  ///
  /// This factory function is responsible for instantiating the
  /// [GeminiGenerativeModelInterface] used for AI interactions. It allows for
  /// customization of the model setup, such as using different HTTP clients, or
  /// for providing mock models during testing. The factory receives this
  /// [FirebaseAiClient] instance as configuration.
  ///
  /// Defaults to a wrapper for the regular [GenerativeModel] constructor,
  /// [defaultGenerativeModelFactory].
  final GenerativeModelFactory modelCreator;

  /// The list of tools to configure by default for this AI instance.
  ///
  /// These [AiTool]s are made available to the AI during every
  /// [generateText] call, in addition to any tools passed directly to that
  /// method.
  final List<AiTool> tools;

  /// The total number of input tokens used by this client.
  int inputTokenUsage = 0;

  /// The total number of output tokens used by this client
  int outputTokenUsage = 0;

  @override
  void switchModel(AiModel newModel) {
    if (newModel is! GeminiModel) {
      throw ArgumentError(
        'Invalid model type: ${newModel.runtimeType} supplied to '
        'FirebaseAiClient.switchModel.',
      );
    }
    _model.value = newModel;
    genUiLogger.info('Switched AI model to: ${newModel.displayName}');
  }

  @override
  ValueListenable<int> get activeRequests => _activeRequests;
  final ValueNotifier<int> _activeRequests = ValueNotifier(0);

  @override
  void dispose() {
    _model.dispose();
    _activeRequests.dispose();
  }

  @override
  Future<String> generateText(
    List<msg.ChatMessage> conversation, {
    Iterable<AiTool> additionalTools = const [],
  }) async {
    _activeRequests.value++;
    try {
      final availableTools = [...tools, ...additionalTools];
      final converter = GeminiContentConverter();
      final contents = converter.toFirebaseAiContent(conversation);
      final adapter = GeminiSchemaAdapter();

      final (
        :generativeAiTools,
        :allowedFunctionNames,
      ) = _setupToolsAndFunctions(
        availableTools: availableTools,
        adapter: adapter,
      );

      var toolUsageCycle = 0;
      const maxToolUsageCycles = 40; // Safety break for tool loops

      final model = modelCreator(
        configuration: this,
        systemInstruction: systemInstruction == null
            ? null
            : Content.system(systemInstruction!),
        tools: generativeAiTools,
        toolConfig: ToolConfig(
          functionCallingConfig: FunctionCallingConfig.auto(),
        ),
      );

      while (toolUsageCycle < maxToolUsageCycles) {
        genUiLogger.fine('Starting tool usage cycle ${toolUsageCycle + 1}.');
        toolUsageCycle++;

        final concatenatedContents = contents
            .map((c) => const JsonEncoder.withIndent('  ').convert(c.toJson()))
            .join('\n');

        genUiLogger.info(
          '****** Performing Inference ******\n'
          '$concatenatedContents\n'
          'With functions:\n'
          '  ${allowedFunctionNames.join(', ')}',
        );
        final inferenceStartTime = DateTime.now();
        final response = await model.generateContent(contents);
        final elapsed = DateTime.now().difference(inferenceStartTime);

        if (response.usageMetadata != null) {
          inputTokenUsage += response.usageMetadata!.promptTokenCount ?? 0;
          outputTokenUsage += response.usageMetadata!.candidatesTokenCount ?? 0;
        }
        genUiLogger.info(
          '****** Completed Inference ******\n'
          'Latency = ${elapsed.inMilliseconds}ms\n'
          'Output tokens = '
          '${response.usageMetadata?.candidatesTokenCount ?? 0}\n'
          'Prompt tokens = ${response.usageMetadata?.promptTokenCount ?? 0}',
        );

        if (response.candidates.isEmpty) {
          genUiLogger.warning(
            'Response has no candidates: ${response.promptFeedback}',
          );
          return '';
        }

        final candidate = response.candidates.first;
        final functionCalls = candidate.content.parts
            .whereType<FunctionCall>()
            .toList();

        if (functionCalls.isEmpty) {
          genUiLogger.fine('Model response contained no function calls.');
          final text = candidate.text ?? '';
          conversation.add(msg.AssistantMessage.text(text));
          genUiLogger.fine('Returning text response: "$text"');
          return text;
        }

        genUiLogger.fine(
          'Model response contained ${functionCalls.length} function calls.',
        );
        final result = await _processFunctionCalls(
          functionCalls: functionCalls,
          availableTools: availableTools,
        );
        final functionResponseParts = result.functionResponseParts;

        final assistantParts = candidate.content.parts
            .map((part) {
              if (part is FunctionCall) {
                return msg.ToolCallPart(
                  id: part.name,
                  toolName: part.name,
                  arguments: part.args,
                );
              }
              if (part is TextPart) {
                return msg.TextPart(part.text);
              }
              return null;
            })
            .whereType<msg.MessagePart>()
            .toList();

        if (assistantParts.isNotEmpty) {
          conversation.add(msg.AssistantMessage(assistantParts));
          genUiLogger.fine(
            'Added assistant message with ${assistantParts.length} parts to '
            'conversation.',
          );
        }

        if (functionResponseParts.isNotEmpty) {
          contents.add(candidate.content);
          contents.add(Content.functionResponses(functionResponseParts));

          final toolResponseParts = functionResponseParts.map((response) {
            return msg.ToolResultPart(
              callId: response.name,
              result: jsonEncode(response.response),
            );
          }).toList();

          if (toolResponseParts.isNotEmpty) {
            conversation.add(msg.ToolResponseMessage(toolResponseParts));
            genUiLogger.fine(
              'Added tool response message with ${toolResponseParts.length} '
              'parts to conversation.',
            );
          }
        }
      }

      genUiLogger.severe(
        'Error: Tool usage cycle exceeded maximum of $maxToolUsageCycles. '
        'No final output was produced.',
        StackTrace.current,
      );
      return '';
    } finally {
      _activeRequests.value--;
    }
  }

  /// The default factory function for creating a [GenerativeModel].
  ///
  /// This function instantiates a standard [GenerativeModel] using the `model`
  /// from the provided [FirebaseAiClient] `configuration`.
  static GeminiGenerativeModelInterface defaultGenerativeModelFactory({
    required FirebaseAiClient configuration,
    Content? systemInstruction,
    List<Tool>? tools,
    ToolConfig? toolConfig,
  }) {
    final geminiModel = configuration._model.value;
    return GeminiGenerativeModel(
      FirebaseAI.googleAI().generativeModel(
        model: geminiModel.type.modelName,
        systemInstruction: systemInstruction,
        tools: tools,
        toolConfig: toolConfig,
      ),
    );
  }

  ({List<Tool>? generativeAiTools, Set<String> allowedFunctionNames})
  _setupToolsAndFunctions({
    required List<AiTool> availableTools,
    required GeminiSchemaAdapter adapter,
  }) {
    genUiLogger.fine('Setting up tools');

    final allTools = availableTools;
    genUiLogger.fine(
      'Available tools: ${allTools.map((t) => t.name).join(', ')}',
    );

    final uniqueAiToolsByName = <String, AiTool>{};
    final toolFullNames = <String>{};
    for (final tool in allTools) {
      if (uniqueAiToolsByName.containsKey(tool.name)) {
        throw AiClientException('Duplicate tool ${tool.name} registered.');
      }
      uniqueAiToolsByName[tool.name] = tool;
      if (tool.name != tool.fullName) {
        if (toolFullNames.contains(tool.fullName)) {
          throw AiClientException(
            'Duplicate tool ${tool.fullName} registered.',
          );
        }
        toolFullNames.add(tool.fullName);
      }
    }

    final functionDeclarations = <FunctionDeclaration>[];
    for (final tool in uniqueAiToolsByName.values) {
      Schema? adaptedParameters;
      if (tool.parameters != null) {
        final result = adapter.adapt(tool.parameters!);
        if (result.errors.isNotEmpty) {
          genUiLogger.warning(
            'Errors adapting parameters for tool ${tool.name}: '
            '${result.errors.join('\n')}',
          );
        }
        adaptedParameters = result.schema;
      }
      final parameters = adaptedParameters?.properties;
      functionDeclarations.add(
        FunctionDeclaration(
          tool.name,
          tool.description,
          parameters: parameters ?? const {},
        ),
      );
      if (tool.name != tool.fullName) {
        functionDeclarations.add(
          FunctionDeclaration(
            tool.fullName,
            tool.description,
            parameters: parameters ?? const {},
          ),
        );
      }
    }
    genUiLogger.fine(
      'Adapted tools to function declarations: '
      '${functionDeclarations.map((d) => d.name).join(', ')}',
    );

    final generativeAiTools = functionDeclarations.isNotEmpty
        ? [Tool.functionDeclarations(functionDeclarations)]
        : null;

    final allowedFunctionNames = <String>{
      ...uniqueAiToolsByName.keys,
      ...toolFullNames,
    };

    genUiLogger.fine(
      'Allowed function names for model: ${allowedFunctionNames.join(', ')}',
    );

    return (
      generativeAiTools: generativeAiTools,
      allowedFunctionNames: allowedFunctionNames,
    );
  }

  Future<
    ({List<FunctionResponse> functionResponseParts, Object? capturedResult})
  >
  _processFunctionCalls({
    required List<FunctionCall> functionCalls,
    required List<AiTool> availableTools,
  }) async {
    genUiLogger.fine(
      'Processing ${functionCalls.length} function calls from model.',
    );
    final functionResponseParts = <FunctionResponse>[];
    for (final call in functionCalls) {
      genUiLogger.fine(
        'Processing function call: ${call.name} with args: ${call.args}',
      );

      final aiTool = availableTools.firstWhere(
        (t) => t.name == call.name || t.fullName == call.name,
        orElse: () =>
            throw AiClientException('Unknown tool ${call.name} called.'),
      );
      JsonMap toolResult;
      try {
        genUiLogger.fine('Invoking tool: ${aiTool.name}');
        toolResult = await aiTool.invoke(call.args);
        genUiLogger.info(
          'Invoked tool ${aiTool.name} with args ${call.args}. '
          'Result: $toolResult',
        );
      } catch (exception, stack) {
        genUiLogger.severe(
          'Error invoking tool ${aiTool.name} with args ${call.args}: ',
          exception,
          stack,
        );
        toolResult = {
          'error': 'Tool ${aiTool.name} failed to execute: $exception',
        };
      }
      functionResponseParts.add(FunctionResponse(call.name, toolResult));
    }
    genUiLogger.fine(
      'Finished processing function calls. Returning '
      '${functionResponseParts.length} responses.',
    );
    return (functionResponseParts: functionResponseParts, capturedResult: null);
  }
}
