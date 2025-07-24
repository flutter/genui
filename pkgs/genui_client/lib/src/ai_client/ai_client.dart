// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:firebase_ai/firebase_ai.dart';

import '../tools/tools.dart';

/// Defines the severity levels for logging messages within the AI client and
/// related components.
typedef GenerativeModelFactory = GenerativeModel Function({
  required AiClient configuration,
  Content? systemInstruction,
  List<Tool>? tools,
  ToolConfig? toolConfig,
});

enum AiLoggingSeverity { trace, debug, info, warning, error, fatal }

typedef AiClientLoggingCallback = void Function(
    AiLoggingSeverity severity, String message);

class AiClientException implements Exception {
  AiClientException(this.message);

  final String message;

  @override
  String toString() => '$AiClientException: $message';
}

/// An interface for accessing a Gemini model.
///
/// This class encapsulates settings for interacting with a generative AI model,
/// including model selection, API keys, retry mechanisms, and tool
/// configurations. It provides a [generateContent] method to interact with
/// the AI model, supporting structured output and tool usage.
class AiClient {
  /// Creates an [AiClient] instance with specified configurations.
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
  /// - [loggingCallback]: A callback for logging events of varying severity.
  /// - [tools]: A list of default [AiTool]s available to the AI.
  /// - [outputToolName]: The name of the internal tool used to force structured
  ///   output from the AI.
  AiClient({
    this.model = 'gemini-2.5-flash',
    this.fileSystem = const LocalFileSystem(),
    this.modelCreator = defaultGenerativeModelFactory,
    this.maxRetries = 8,
    this.initialDelay = const Duration(seconds: 1),
    this.minDelay = const Duration(seconds: 8),
    this.maxConcurrentJobs = 20,
    this.loggingCallback,
    this.tools = const <AiTool>[],
    this.outputToolName = 'provideFinalOutput',
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

  /// The name of the Gemini model to use.
  ///
  /// This identifier specifies which version or type of the generative AI model
  /// will be invoked for content generation.
  ///
  /// Defaults to 'gemini-2.5-flash'.
  final String model;

  /// The file system to use for accessing files.
  ///
  /// While not directly used by [AiClient]'s core content generation logic,
  /// this [FileSystem] instance can be utilized by [AiTool] implementations
  /// that require file read/write capabilities.
  ///
  /// Defaults to a [LocalFileSystem] instance, providing access to the local
  /// machine's file system.
  final FileSystem fileSystem;

  /// The maximum number of retries to attempt when generating content.
  ///
  /// If an API call to the generative model fails with a transient error (like
  /// [FirebaseAIException] or [ServerException]), the client will attempt
  /// to retry the call up to this many times.
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
  /// [AiClient] operations or other concurrent tasks. The [generateContent]
  /// method itself is a single asynchronous operation and does not directly
  /// enforce this limit.
  ///
  /// Defaults to 20.
  final int maxConcurrentJobs;

  /// A callback to use for logging messages.
  ///
  /// If provided, this function will be invoked with a severity level and a
  /// message string for various events occurring within the client, such as
  /// retry attempts, errors, or informational messages about tool invocations.
  /// This is useful for debugging and monitoring the client's behavior.
  ///
  /// Defaults to null (no logging).
  final AiClientLoggingCallback? loggingCallback;

  /// A function to use for creating the model itself.
  ///
  /// This factory function is responsible for instantiating the
  /// [GenerativeModel] used for AI interactions. It allows for customization of
  /// the model setup, such as using different HTTP clients, or for providing
  /// mock models during testing.
  /// The factory receives this [AiClient] instance
  /// as configuration.
  ///
  /// Defaults to a wrapper for the regular [GenerativeModel] constructor,
  /// [defaultGenerativeModelFactory].
  final GenerativeModelFactory modelCreator;

  /// The list of tools to configure by default for this AI instance.
  ///
  /// These [AiTool]s are made available to the AI during every
  /// [generateContent] call, in addition to any tools passed
  /// directly to that method.
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

  /// Generates structured content based on the provided prompts and output
  /// schema.
  ///
  /// This method orchestrates the interaction with the generative AI model. It
  /// sends the given [conversation] and an [outputSchema] that defines the
  /// expected structure of the AI's response. The [conversation] is updated
  /// in place with the results of the tool-calling conversation.
  ///
  /// The AI is configured to use "forced tool calling", meaning it's expected
  /// to respond by either:
  /// 1. Calling one of the available [AiTool]s (from [tools] or
  ///    [additionalTools]). If a tool is called, its `invoke` method is
  ///    executed, and the result is sent back to the AI in a subsequent
  //
  ///    request.
  /// 2. Calling a special internal tool (named by [outputToolName]) whose
  ///    argument is the final structured data matching [outputSchema].
  ///
  /// - [conversation]: A list of [Content] objects representing the input to
  ///   the AI. This list will be modified in place to include the tool calling
  ///   conversation.
  /// - [outputSchema]: A [Schema] defining the structure of the desired output
  ///   `T`.
  /// - [additionalTools]: A list of [AiTool]s to make available to the AI for
  ///   this specific call, in addition to the default [tools].
  Future<T?> generateContent<T extends Object>(
    List<Content> conversation,
    Schema outputSchema, {
    Iterable<AiTool> additionalTools = const [],
    Content? systemInstruction,
  }) async {
    return await _generateContentWithRetries(
      conversation,
      outputSchema,
      [...tools, ...additionalTools],
      systemInstruction,
    );
  }

  /// The default factory function for creating a [GenerativeModel].
  ///
  /// This function instantiates a standard [GenerativeModel] using the
  /// `model` from the provided [AiClient] `configuration`.
  static GenerativeModel defaultGenerativeModelFactory({
    required AiClient configuration,
    Content? systemInstruction,
    List<Tool>? tools,
    ToolConfig? toolConfig,
  }) {
    return FirebaseAI.googleAI().generativeModel(
      model: configuration.model,
      systemInstruction: systemInstruction,
      tools: tools,
      toolConfig: toolConfig,
    );
  }

  void _error(String message, [StackTrace? stackTrace]) {
    loggingCallback?.call(AiLoggingSeverity.error,
        stackTrace != null ? '$message\n$stackTrace' : message);
  }

  void _warn(String message, [StackTrace? stackTrace]) {
    loggingCallback?.call(AiLoggingSeverity.warning,
        stackTrace != null ? '$message\n$stackTrace' : message);
  }

  void _log(String message, [StackTrace? stackTrace]) {
    loggingCallback?.call(AiLoggingSeverity.info,
        stackTrace != null ? '$message\n$stackTrace' : message);
  }

  Future<T?> _generateContentWithRetries<T extends Object>(
    List<Content> contents,
    Schema outputSchema,
    List<AiTool> availableTools,
    Content? systemInstruction,
  ) async {
    var attempts = 0;
    var delay = initialDelay;
    final maxTries = maxRetries + 1; // Retries plus the first attempt.

    Future<void> onFail(Exception exception) async {
      attempts++;
      if (attempts >= maxTries) {
        _warn('Max retries of $maxRetries reached.');
        throw exception;
      }
      _error(
        'Received exception, retrying in ${delay + minDelay}.: $exception',
      );
      // Make the delay at least minDelay long, since the reset window
      // for exceeding the number of requests is 10 seconds long, and
      // requesting it faster than that just means it makes us wait longer.
      await Future<void>.delayed(delay + minDelay);
      delay *= 2;
    }

    while (attempts < maxTries) {
      try {
        final result = await _generateContentForcedToolCalling<T>(
          contents,
          outputSchema,
          availableTools,
          systemInstruction,
          // Reset the delay and attempts on success.
          () {
            delay = initialDelay;
            attempts = 0;
          },
        );
        return result;
      } on FirebaseAIException catch (exception) {
        if (exception.message.contains(
          '$model is not found for API version',
        )) {
          // If the model is not found, then just throw an exception.
          throw AiClientException(exception.message);
        }
        await onFail(exception);
      } catch (exception, stack) {
        _error(
            'Received '
            '${exception.runtimeType}: $exception',
            stack);
        // For other exceptions, rethrow immediately.
        rethrow;
      }
    }
    // This line should be unreachable if maxRetries > 0,
    // but is needed for static analysis.
    throw StateError('Exceeded maximum retries without throwing an exception.');
  }

  Future<T?> _generateContentForcedToolCalling<T extends Object>(
    // This list is modified to include tool calls and results.
    List<Content> contents,
    Schema outputSchema,
    List<AiTool> availableTools,
    Content? systemInstruction,
    void Function() onSuccess,
  ) async {
    // Create an "output" tool that copies its args into the output.
    final finalOutputAiTool = DynamicAiTool<Map<String, Object?>>(
      name: outputToolName,
      description:
          'Returns the final output. Call this function ONLY when you have '
          'your complete structured output that conforms to the required '
          'schema. Do not call this if you need to use other tools first. You '
          'MUST call this tool when you are done.',
      // Wrap the outputSchema in an object so that the output schema isn't
      // limited to objects.
      parameters: Schema.object(
        properties: {'output': outputSchema},
      ),
      invokeFunction: (args) async => args, // Invoke is a pass-through
    );
    // Ensure allAiTools doesn't have duplicates by name, and prioritize the
    // finalOutputAiTool
    final uniqueAiToolsByName = <String, AiTool>{};
    final toolFullNames = <String>{};
    for (final tool in [...availableTools, finalOutputAiTool]) {
      if (uniqueAiToolsByName.containsKey(tool.name)) {
        throw AiClientException('Duplicate tool ${tool.name} registered.');
      }
      uniqueAiToolsByName[tool.name] = tool;
      if (tool.name != tool.fullName) {
        if (toolFullNames.contains(tool.fullName)) {
          throw AiClientException(
              'Duplicate tool ${tool.fullName} registered.');
        }
        toolFullNames.add(tool.fullName);
      }
    }

    // Registers tools under both their name and their fullName (if different),
    // because `toFunctionDeclarations` will return both declarations if they
    // are different.
    final generativeAiTools = [
      Tool.functionDeclarations(
        [...uniqueAiToolsByName.values.map((t) => t.toFunctionDeclarations())]
            .expand((e) => e)
            .toList(),
      )
    ];
    final allowedFunctionNames = <String>{
      ...uniqueAiToolsByName.keys,
      ...toolFullNames,
    };

    var toolUsageCycle = 0;
    const maxToolUsageCycles = 40; // Safety break for tool loops
    T? capturedResult;

    final model = modelCreator(
      configuration: this,
      systemInstruction: systemInstruction,
      tools: generativeAiTools,
      toolConfig: ToolConfig(
        functionCallingConfig: FunctionCallingConfig.any(
          allowedFunctionNames.toSet(),
        ),
      ),
    );

    while (toolUsageCycle < maxToolUsageCycles && capturedResult == null) {
      toolUsageCycle++;
      _log('Generating content with:');
      for (final content in contents) {
        _log(const JsonEncoder.withIndent('  ').convert(content.toJson()));
      }
      _log(
        'With functions: '
        '${allowedFunctionNames.join(', ')}',
      );
      final response = await model.generateContent(contents);

      // If the generate call succeeds, we need to reset the delay for the next
      // retry. If the generate call throws, this won't get called, and the
      // delay will double.
      onSuccess();

      if (response.usageMetadata != null) {
        inputTokenUsage += response.usageMetadata!.promptTokenCount ?? 0;
        outputTokenUsage += response.usageMetadata!.candidatesTokenCount ?? 0;
      }

      if (response.candidates.isEmpty) {
        _warn('Response has no candidates: ${response.promptFeedback}');
        return null;
      }

      final candidate = response.candidates.first;
      final functionCalls =
          candidate.content.parts.whereType<FunctionCall>().toList();

      if (functionCalls.isEmpty) {
        _warn(
          'Model did not call any function. FinishReason: '
          '${candidate.finishReason}. Text: "${candidate.text}"',
        );
        if (candidate.text != null && candidate.text!.trim().isNotEmpty) {
          _warn(
            'Model returned direct text instead of a tool call. This might be '
            'an error or unexpected LLM behavior for forced tool calling.',
          );
          return null;
        }
        _log(
          'No function calls and no text. FinishReason: '
          '${candidate.finishReason} '
          'PromptFeedback: ${response.promptFeedback}',
        );
        return null;
      }

      final functionResponseParts = <FunctionResponse>[];
      for (final call in functionCalls) {
        if (call.name == outputToolName) {
          try {
            capturedResult = (call.args['parameters'] as Map)['output'] as T?;
          } catch (e, s) {
            _error('Unable to read output: $call [${call.args}]: $e', s);
          }
          _log(
            'Invoked output tool ${call.name} with args ${call.args}. '
            'Final result: $capturedResult',
          );
          continue;
        }

        final aiTool = availableTools.firstWhere(
          (t) => t.name == call.name || t.fullName == call.name,
          orElse: () =>
              throw AiClientException('Unknown tool ${call.name} called.'),
        );
        Map<String, Object?> toolResult;
        try {
          toolResult = await aiTool.invoke(call.args);
          _log(
            'Invoked tool ${aiTool.name} with args ${call.args}. '
            'Result: $toolResult',
          );
        } catch (exception, stack) {
          _error(
              'Error invoking tool ${aiTool.name} with args ${call.args}: '
              '$exception\n',
              stack);
          toolResult = {
            'error': 'Tool ${aiTool.name} failed to execute: $exception'
          };
        }
        functionResponseParts.add(FunctionResponse(call.name, toolResult));
      }

      // If some functions were called, add their responses to the history and
      // try again.
      if (functionResponseParts.isNotEmpty) {
        // Add the model's previous response that contained the function call(s)
        // to the history so it knows what it asked for.
        contents.add(candidate.content);
        contents.add(Content.functionResponses(functionResponseParts));
      }
    }
    if (capturedResult == null) {
      _error(
        'Error: Tool usage cycle exceeded maximum of $maxToolUsageCycles. '
        'No final output was produced.',
      );
    }
    return capturedResult;
  }
}
