// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:dart_schema_builder/dart_schema_builder.dart' as dsb;
import 'package:file/file.dart';
import 'package:file/local.dart';
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
      required GeminiAiClient configuration,
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
/// including model selection, API keys, retry mechanisms, and tool
/// configurations. It provides a [generateContent] method to interact with the
/// AI model, supporting structured output and tool usage.
class GeminiAiClient implements AiClient {
  /// Creates an [GeminiAiClient] instance with specified configurations.
  ///
  /// - [model]: The identifier of the generative AI model to use.
  /// - [fileSystem]: The [FileSystem] instance for file operations, primarily
  ///   used by tools.
  /// - [modelCreator]: A factory function to create the [GenerativeModel].
  /// - [maxRetries]: Maximum number of retries for API calls on transient
  ///   errors.
  /// - [initialDelay]: Initial delay for the exponential backoff retry
  ///   strategy.
  /// - [maxConcurrentJobs]: Intended for managing concurrent AI operations,
  ///   though not directly enforced by [generateContent] itself.
  /// - [tools]: A list of default [AiTool]s available to the AI.
  /// - [outputToolName]: The name of the internal tool used to force structured
  ///   output from the AI.
  GeminiAiClient({
    GeminiModelType model = GeminiModelType.flash,
    this.systemInstruction,
    this.fileSystem = const LocalFileSystem(),
    this.modelCreator = defaultGenerativeModelFactory,
    this.maxRetries = 8,
    this.initialDelay = const Duration(seconds: 1),
    this.minDelay = const Duration(seconds: 8),
    this.maxConcurrentJobs = 20,
    this.tools = const <AiTool>[],
    this.outputToolName = 'provideFinalOutput',
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

  /// The file system to use for accessing files.
  ///
  /// While not directly used by [GeminiAiClient]'s core content generation
  /// logic, this [FileSystem] instance can be utilized by [AiTool]
  /// implementations that require file read/write capabilities.
  ///
  /// Defaults to a [LocalFileSystem] instance, providing access to the local
  /// machine's file system.
  final FileSystem fileSystem;

  /// The maximum number of retries to attempt when generating content.
  ///
  /// If an API call to the generative model fails with a transient error (like
  /// [FirebaseAIException]), the client will attempt to retry the call up to
  /// this many times.
  ///
  /// Defaults to 8 retries.
  final int maxRetries;

  /// The initial delay between retries in seconds.
  ///
  /// This duration is used for the first retry attempt. Subsequent retries
  /// employ an exponential backoff strategy, where the delay doubles after each
  /// failed attempt, up to the [maxRetries] limit.
  ///
  /// Defaults to 1 second.
  final Duration initialDelay;

  /// The minimum length of time to delay.
  ///
  /// Since the reset window for quota violations is 10 seconds, this shouldn't
  /// be much less than that, or it will just wait longer.
  ///
  /// Defaults to 8 seconds.
  final Duration minDelay;

  /// The maximum number of concurrent jobs to run.
  ///
  /// This property is intended for systems that might manage multiple
  /// [GeminiAiClient] operations or other concurrent tasks. The
  /// [generateContent] method itself is a single asynchronous operation and
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
  /// [GeminiAiClient] instance as configuration.
  ///
  /// Defaults to a wrapper for the regular [GenerativeModel] constructor,
  /// [defaultGenerativeModelFactory].
  final GenerativeModelFactory modelCreator;

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

  /// The total number of input tokens used by this client.
  int inputTokenUsage = 0;

  /// The total number of output tokens used by this client
  int outputTokenUsage = 0;

  @override
  void switchModel(AiModel newModel) {
    if (newModel is! GeminiModel) {
      throw ArgumentError(
        'Invalid model type: ${newModel.runtimeType} supplied to '
        '$GeminiAiClient.switchModel.',
      );
    }
    _model.value = newModel;
    genUiLogger.info('Switched AI model to: ${newModel.displayName}');
  }

  /// Generates structured content based on the provided prompts and output
  /// schema.
  ///
  /// This method orchestrates the interaction with the generative AI model. It
  /// sends the given [conversation] and an [outputSchema] that defines the
  /// expected structure of the AI's response. The [conversation] is updated in
  /// place with the results of the tool-calling conversation.
  ///
  /// The AI is configured to use "forced tool calling", meaning it's expected
  /// to respond by either:
  ///
  /// 1. Calling one of the available [AiTool]s (from [tools] or
  ///    [additionalTools]). If a tool is called, its `invoke` method is
  ///    executed, and the result is sent back to the AI in a subsequent
  ///    request.
  /// 2. Calling a special internal tool (named by [outputToolName]) whose
  ///    argument is the final structured data matching [outputSchema].
  ///
  /// - [conversation]: A list of [Content] objects representing the input to
  ///   the AI. This list will be modified in place to include the tool calling
  ///   conversation.
  /// - [outputSchema]: A [dsb.Schema] defining the structure of the desired
  ///   output `T`.
  /// - [additionalTools]: A list of [AiTool]s to make available to the AI for
  ///   this specific call, in addition to the default [tools].
  @override
  Future<T?> generateContent<T extends Object>(
    List<msg.ChatMessage> conversation,
    dsb.Schema outputSchema, {
    Iterable<AiTool> additionalTools = const [],
  }) async {
    return await _generateContentWithRetries(conversation, outputSchema, [
      ...tools,
      ...additionalTools,
    ]);
  }

  @override
  Future<String> generateText(
    List<msg.ChatMessage> conversation, {
    Iterable<AiTool> additionalTools = const [],
  }) async {
    return await _generateTextWithRetries(conversation, [
      ...tools,
      ...additionalTools,
    ]);
  }

  /// The default factory function for creating a [GenerativeModel].
  ///
  /// This function instantiates a standard [GenerativeModel] using the `model`
  /// from the provided [GeminiAiClient] `configuration`.
  static GeminiGenerativeModelInterface defaultGenerativeModelFactory({
    required GeminiAiClient configuration,
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

  Future<T?> _generateContentWithRetries<T extends Object>(
    List<msg.ChatMessage> contents,
    dsb.Schema outputSchema,
    List<AiTool> availableTools,
  ) async {
    genUiLogger.fine('Generating content with retries.');
    return _generateWithRetries<T?>(
      (onSuccess) async =>
          await _generate(
                messages: contents,
                availableTools: availableTools,
                onSuccess: onSuccess,
                outputSchema: outputSchema,
              )
              as T?,
    );
  }

  Future<String> _generateTextWithRetries(
    List<msg.ChatMessage> contents,
    List<AiTool> availableTools,
  ) async {
    genUiLogger.fine('Generating text with retries.');
    return _generateWithRetries<String>(
      (onSuccess) async =>
          await _generate(
                messages: contents,
                availableTools: availableTools,
                onSuccess: onSuccess,
              )
              as String,
    );
  }

  Future<T> _generateWithRetries<T>(
    Future<T> Function(void Function() onSuccess) generationFunction,
  ) async {
    var attempts = 0;
    var delay = initialDelay;
    final maxTries = maxRetries + 1; // Retries plus the first attempt.
    genUiLogger.fine('Starting generation with up to $maxRetries retries.');

    Future<void> onFail(Exception exception) async {
      attempts++;
      if (attempts >= maxTries) {
        genUiLogger.warning('Max retries of $maxRetries reached.');
        throw exception;
      }
      // Make the delay at least minDelay long, since the reset window for
      // exceeding the number of requests is 10 seconds long, and requesting it
      // faster than that just means it makes us wait longer.
      final waitTime = delay + minDelay;
      genUiLogger.severe(
        'Received exception, retrying in $waitTime. Attempt $attempts of '
        '$maxTries. Exception: $exception',
      );
      await Future<void>.delayed(waitTime);
      delay *= 2;
    }

    while (attempts < maxTries) {
      try {
        final result = await generationFunction(
          // Reset the delay and attempts on success.
          () {
            delay = initialDelay;
            attempts = 0;
          },
        );
        genUiLogger.fine('Generation successful.');
        return result;
      } on FirebaseAIException catch (exception) {
        if (exception.message.contains(
          '${_model.value.type.modelName} is not found for API version',
        )) {
          // If the model is not found, then just throw an exception.
          throw AiClientException(exception.message);
        }
        await onFail(exception);
      } catch (exception, stack) {
        genUiLogger.severe(
          'Received '
          '${exception.runtimeType}: $exception',
          exception,
          stack,
        );
        // For other exceptions, rethrow immediately.
        rethrow;
      }
    }
    // This line should be unreachable if maxRetries > 0, but is needed for
    // static analysis.
    throw StateError('Exceeded maximum retries without throwing an exception.');
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
        ? DynamicAiTool<JsonMap>(
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
      JsonMap toolResult;
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
    // This list is modified to include tool calls and results.
    required List<msg.ChatMessage> messages,
    required List<AiTool> availableTools,
    required void Function() onSuccess,
    dsb.Schema? outputSchema,
  }) async {
    final isForcedToolCalling = outputSchema != null;
    final converter = GeminiContentConverter();
    final contents = converter.toFirebaseAiContent(messages);
    final adapter = GeminiSchemaAdapter();

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

      final concatenatedContents = contents
          .map((c) => const JsonEncoder.withIndent('  ').convert(c.toJson()))
          .join('\n');

      genUiLogger.info(
        '''****** Performing Inference ******\n$concatenatedContents
With functions:
  '${allowedFunctionNames.join(', ')}',
  ''',
      );
      final inferenceStartTime = DateTime.now();
      final response = await model.generateContent(contents);
      final elapsed = DateTime.now().difference(inferenceStartTime);

      onSuccess();

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
          if (candidate.text != null) {
            messages.add(msg.AssistantMessage.text(candidate.text!));
          }
          genUiLogger.fine(
            'Model returned text but no function calls with forced tool '
            'calling, so returning null.',
          );
          return null;
        } else {
          final text = candidate.text ?? '';
          messages.add(msg.AssistantMessage.text(text));
          genUiLogger.fine('Returning text response: "$text"');
          return text;
        }
      }

      genUiLogger.fine(
        'Model response contained ${functionCalls.length} function calls.',
      );
      final result = await _processFunctionCalls(
        functionCalls: functionCalls,
        isForcedToolCalling: isForcedToolCalling,
        availableTools: availableTools,
        capturedResult: capturedResult,
      );
      capturedResult = result.capturedResult;
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
        messages.add(msg.AssistantMessage(assistantParts));
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
          messages.add(msg.ToolResponseMessage(toolResponseParts));
          genUiLogger.fine(
            'Added tool response message with ${toolResponseParts.length} '
            'parts to conversation.',
          );
        }
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
