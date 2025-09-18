// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:dart_schema_builder/dart_schema_builder.dart' as dsb;
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_genui/flutter_genui.dart';

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

/// A basic implementation of [AiClient] for accessing a Gemini model.
///
/// This class encapsulates settings for interacting with a generative AI model,
/// including model selection, API keys, retry mechanisms, and tool
/// configurations. It provides a [generateContent] method to interact with the
/// AI model, supporting structured output and tool usage.
class FirebaseAiClient implements AiClient {
  /// Creates an [FirebaseAiClient] instance with specified configurations.
  ///
  /// - [tools]: A list of default [AiTool]s available to the AI.
  /// - [outputToolName]: The name of the internal tool used to force structured
  ///   output from the AI.
  FirebaseAiClient({
    this.systemInstruction,
    this.tools = const <AiTool>[],
    this.outputToolName = 'provideFinalOutput',
    this.modelCreator = defaultGenerativeModelFactory,
  }) {
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

  /// The list of tools to configure by default for this AI instance.
  ///
  /// These [AiTool]s are made available to the AI during every
  /// [generateContent] call, in addition to any tools passed directly to that
  /// method.
  final List<AiTool> tools;

  /// The name of an internal pseudo-tool used to retrieve the final structured
  /// output from the AI.
  ///
  /// This only needs to be provided in case of name collision with another
  /// tool. It is used internally to fetch the final output to return from the
  /// [generateContent] method.
  ///
  /// Defaults to 'provideFinalOutput'.
  final String outputToolName;

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

  /// The total number of input tokens used by this client.
  int inputTokenUsage = 0;

  /// The total number of output tokens used by this client
  int outputTokenUsage = 0;

  @override
  ValueListenable<int> get activeRequests => _activeRequests;
  final ValueNotifier<int> _activeRequests = ValueNotifier(0);

  @override
  void dispose() {
    _activeRequests.dispose();
  }

  @override
  Future<T?> generateContent<T extends Object>(
    Iterable<ChatMessage> conversation,
    dsb.Schema outputSchema, {
    Iterable<AiTool> additionalTools = const [],
  }) async {
    _activeRequests.value++;
    try {
      return await _generate(
            messages: conversation,
            outputSchema: outputSchema,
            availableTools: [...tools, ...additionalTools],
          )
          as T?;
    } finally {
      _activeRequests.value--;
    }
  }

  @override
  Future<String> generateText(
    Iterable<ChatMessage> conversation, {
    Iterable<AiTool> additionalTools = const [],
  }) async {
    _activeRequests.value++;
    try {
      return await _generate(
            messages: conversation,
            availableTools: [...tools, ...additionalTools],
          )
          as String;
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
    return GeminiGenerativeModel(
      FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.5-flash',
        systemInstruction: systemInstruction,
        tools: tools,
        toolConfig: toolConfig,
      ),
    );
  }

  ({List<Tool>? generativeAiTools, Set<String> allowedFunctionNames})
  _setupToolsAndFunctions({
    required bool isForcedToolCalling,
    required List<AiTool> availableTools,
    required GeminiSchemaAdapter adapter,
    required dsb.Schema? outputSchema,
  }) {
    genUiLogger.fine(
      'Setting up tools'
      '${isForcedToolCalling ? ' with forced tool calling' : ''}',
    );
    // Create an "output" tool that copies its args into the output.
    final finalOutputAiTool = isForcedToolCalling
        ? DynamicAiTool<Map<String, Object?>>(
            name: outputToolName,
            description:
                '''Returns the final output. Call this function ONLY when you have your complete structured output that conforms to the required schema. Do not call this if you need to use other tools first. You MUST call this tool when you are done.''',
            // Wrap the outputSchema in an object so that the output schema
            // isn't limited to objects.
            parameters: dsb.S.object(properties: {'output': outputSchema!}),
            invokeFunction: (args) async => args, // Invoke is a pass-through
          )
        : null;

    final allTools = isForcedToolCalling
        ? [...availableTools, finalOutputAiTool!]
        : availableTools;
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
    required bool isForcedToolCalling,
    required List<AiTool> availableTools,
    Object? capturedResult,
  }) async {
    genUiLogger.fine(
      'Processing ${functionCalls.length} function calls from model.',
    );
    final functionResponseParts = <FunctionResponse>[];
    for (final call in functionCalls) {
      genUiLogger.fine(
        'Processing function call: ${call.name} with args: ${call.args}',
      );
      if (isForcedToolCalling && call.name == outputToolName) {
        try {
          capturedResult = call.args['output'];
          genUiLogger.fine(
            'Captured final output from tool "$outputToolName".',
          );
        } catch (exception, stack) {
          genUiLogger.severe(
            'Unable to read output: $call [${call.args}]',
            exception,
            stack,
          );
        }
        genUiLogger.info(
          '****** Gen UI Output ******.\n'
          '${const JsonEncoder.withIndent('  ').convert(capturedResult)}',
        );
        break;
      }

      final aiTool = availableTools.firstWhere(
        (t) => t.name == call.name || t.fullName == call.name,
        orElse: () =>
            throw AiClientException('Unknown tool ${call.name} called.'),
      );
      Map<String, Object?> toolResult;
      try {
        genUiLogger.fine('Invoking tool: ${aiTool.name}');
        toolResult = await aiTool.invoke(call.args);
        genUiLogger.info(
          'Invoked tool ${aiTool.name} with args ${call.args}. ',
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
    return (
      functionResponseParts: functionResponseParts,
      capturedResult: capturedResult,
    );
  }

  Future<Object?> _generate({
    required Iterable<ChatMessage> messages,
    required List<AiTool> availableTools,
    dsb.Schema? outputSchema,
  }) async {
    final isForcedToolCalling = outputSchema != null;
    final converter = GeminiContentConverter();
    final adapter = GeminiSchemaAdapter();

    // A local copy of the incoming messages which is updated with tool results
    // as they are generated.
    final mutableContent = converter.toFirebaseAiContent(messages);

    final (:generativeAiTools, :allowedFunctionNames) = _setupToolsAndFunctions(
      isForcedToolCalling: isForcedToolCalling,
      availableTools: availableTools,
      adapter: adapter,
      outputSchema: outputSchema,
    );

    var toolUsageCycle = 0;
    const maxToolUsageCycles = 40; // Safety break for tool loops
    Object? capturedResult;

    final model = modelCreator(
      configuration: this,
      systemInstruction: systemInstruction == null
          ? null
          : Content.system(systemInstruction!),
      tools: generativeAiTools,
      toolConfig: isForcedToolCalling
          ? ToolConfig(
              functionCallingConfig: FunctionCallingConfig.any(
                allowedFunctionNames.toSet(),
              ),
            )
          : ToolConfig(functionCallingConfig: FunctionCallingConfig.auto()),
    );

    while (toolUsageCycle < maxToolUsageCycles) {
      genUiLogger.fine('Starting tool usage cycle ${toolUsageCycle + 1}.');
      if (isForcedToolCalling && capturedResult != null) {
        genUiLogger.fine('Captured result found, exiting tool usage loop.');
        break;
      }
      toolUsageCycle++;

      final concatenatedContents = mutableContent
          .map((c) => const JsonEncoder.withIndent('  ').convert(c.toJson()))
          .join('\n');

      genUiLogger.info(
        '''****** Performing Inference ******\n$concatenatedContents
With functions:
  '${allowedFunctionNames.join(', ')}',
  ''',
      );
      final inferenceStartTime = DateTime.now();
      final response = await model.generateContent(mutableContent);
      final elapsed = DateTime.now().difference(inferenceStartTime);

      if (response.usageMetadata != null) {
        inputTokenUsage += response.usageMetadata!.promptTokenCount ?? 0;
        outputTokenUsage += response.usageMetadata!.candidatesTokenCount ?? 0;
      }
      genUiLogger.info(
        '****** Completed Inference ******\n'
        'Latency = ${elapsed.inMilliseconds}ms\n'
        'Output tokens = ${response.usageMetadata?.candidatesTokenCount ?? 0}\n'
        'Prompt tokens = ${response.usageMetadata?.promptTokenCount ?? 0}',
      );

      if (response.candidates.isEmpty) {
        genUiLogger.warning(
          'Response has no candidates: ${response.promptFeedback}',
        );
        return isForcedToolCalling ? null : '';
      }

      final candidate = response.candidates.first;
      final functionCalls = candidate.content.parts
          .whereType<FunctionCall>()
          .toList();

      if (functionCalls.isEmpty) {
        genUiLogger.fine('Model response contained no function calls.');
        if (isForcedToolCalling) {
          genUiLogger.warning(
            'Model did not call any function. FinishReason: '
            '${candidate.finishReason}. Text: "${candidate.text}" ',
          );
          if (candidate.text != null && candidate.text!.trim().isNotEmpty) {
            genUiLogger.warning(
              'Model returned direct text instead of a tool call. This might '
              'be an error or unexpected AI behavior for forced tool calling.',
            );
          }
          genUiLogger.fine(
            'Model returned text but no function calls with forced tool '
            'calling, so returning null.',
          );
          return null;
        } else {
          final text = candidate.text ?? '';
          mutableContent.add(candidate.content);
          genUiLogger.fine('Returning text response: "$text"');
          return text;
        }
      }

      genUiLogger.fine(
        'Model response contained ${functionCalls.length} function calls.',
      );
      mutableContent.add(candidate.content);
      genUiLogger.fine(
        'Added assistant message with ${candidate.content.parts.length} '
        'parts to conversation.',
      );

      final result = await _processFunctionCalls(
        functionCalls: functionCalls,
        isForcedToolCalling: isForcedToolCalling,
        availableTools: availableTools,
        capturedResult: capturedResult,
      );
      capturedResult = result.capturedResult;
      final functionResponseParts = result.functionResponseParts;

      if (functionResponseParts.isNotEmpty) {
        mutableContent.add(Content.functionResponses(functionResponseParts));
        genUiLogger.fine(
          'Added tool response message with ${functionResponseParts.length} '
          'parts to conversation.',
        );
      }
    }

    if (isForcedToolCalling) {
      if (toolUsageCycle >= maxToolUsageCycles) {
        genUiLogger.severe(
          'Error: Tool usage cycle exceeded maximum of $maxToolUsageCycles. ',
          'No final output was produced.',
          StackTrace.current,
        );
      }
      genUiLogger.fine('Exited tool usage loop. Returning captured result.');
      return capturedResult;
    } else {
      genUiLogger.severe(
        'Error: Tool usage cycle exceeded maximum of $maxToolUsageCycles. ',
        'No final output was produced.',
        StackTrace.current,
      );
      return '';
    }
  }
}
