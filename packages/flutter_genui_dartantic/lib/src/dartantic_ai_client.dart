// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dartantic_ai/dartantic_ai.dart';
import 'package:dartantic_interface/dartantic_interface.dart' as dartantic;
import 'package:flutter/foundation.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart' as dsb;
import 'package:json_schema/json_schema.dart' as js;
import 'package:logging/logging.dart';

import 'dartantic_content_converter.dart';
import 'dartantic_schema_adapter.dart';

/// Represents an API key with a name and value.
class ApiKey {
  /// Creates an [ApiKey] with the specified name and value.
  const ApiKey({
    required this.name,
    required this.value,
  });

  /// The name of the API key (e.g., 'GOOGLE_API_KEY', 'OPENAI_API_KEY').
  final String name;

  /// The value of the API key.
  final String value;
}

/// A factory for creating an [Agent].
///
/// This is used to allow for custom agent creation, for example, for testing.
typedef AgentFactory =
    Agent Function({
      required String provider,
      String? model,
      Map<String, dynamic>? options,
      List<dartantic.Tool>? tools,
    });

/// A basic implementation of [AiClient] for accessing AI models through Dartantic.
///
/// This class encapsulates settings for interacting with a generative AI model,
/// including provider selection, model configuration, and tool configurations.
/// It provides a [generateContent] method to interact with the AI model,
/// supporting structured output and tool usage.
class DartanticAiClient implements AiClient {
  /// Creates a [DartanticAiClient] instance with specified configurations.
  ///
  /// - [provider]: The AI provider to use (e.g., 'openai', 'google', 'anthropic').
  /// - [model]: Optional model name to use with the provider.
  /// - [systemInstruction]: Optional system instruction for the AI.
  /// - [tools]: A list of default [AiTool]s available to the AI.
  /// - [outputToolName]: The name of the internal tool used to force structured
  ///   output from the AI.
  /// - [apiKey]: Optional API key to set in the Agent environment.
  /// - [agentFactory]: A function to use for creating the agent itself.
  DartanticAiClient({
    required this.provider,
    this.model,
    this.systemInstruction,
    this.tools = const <AiTool>[],
    this.outputToolName = 'provideFinalOutput',
    this.apiKey,
    this.agentFactory = defaultAgentFactory,
  }) {
    // Set API key in Agent environment if provided
    if (apiKey != null) {
      Agent.environment[apiKey!.name] = apiKey!.value;
    }

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

  /// The AI provider to use (e.g., 'openai', 'google', 'anthropic').
  final String provider;

  /// The model name to use with the provider.
  final String? model;

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

  /// Optional API key to set in the Agent environment.
  final ApiKey? apiKey;

  /// A function to use for creating the agent itself.
  ///
  /// This factory function is responsible for instantiating the
  /// [Agent] used for AI interactions. It allows for
  /// customization of the agent setup, such as using different configurations,
  /// or for providing mock agents during testing.
  ///
  /// Defaults to a wrapper for the regular [Agent] constructor,
  /// [defaultAgentFactory].
  final AgentFactory agentFactory;

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

  /// The default factory function for creating an [Agent].
  ///
  /// This function instantiates a standard [Agent] using the provided
  /// configuration.
  static Agent defaultAgentFactory({
    required String provider,
    String? model,
    Map<String, dynamic>? options,
    List<dartantic.Tool>? tools,
  }) {
    final modelString = model != null ? '$provider:$model' : provider;
    return Agent(
      modelString,
      tools: tools,
      temperature: options?['temperature'] as double?,
    );
  }

  /// Sets up tools and converts them to dartantic format.
  List<dartantic.Tool> _setupTools({
    required List<AiTool> availableTools,
    required DartanticSchemaAdapter adapter,
    required dsb.Schema? outputSchema,
  }) {
    final isForcedToolCalling = outputSchema != null;

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

    final uniqueAiToolsByName = <String, AiTool>{};
    for (final tool in allTools) {
      if (uniqueAiToolsByName.containsKey(tool.name)) {
        throw AiClientException('Duplicate tool ${tool.name} registered.');
      }
      uniqueAiToolsByName[tool.name] = tool;
    }

    final dartanticTools = <dartantic.Tool>[];
    for (final tool in uniqueAiToolsByName.values) {
      js.JsonSchema? adaptedParameters;
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

      dartanticTools.add(
        dartantic.Tool<Map<String, dynamic>>(
          name: tool.name,
          description: tool.description,
          inputSchema: adaptedParameters,
          onCall: (args) async {
            try {
              _logger.info('Invoking tool ${tool.name} with args $args');
              final result = await tool.invoke(args);
              _logger.info('Tool ${tool.name} result: $result');
              return result;
            } catch (exception, stack) {
              _logger.severe(
                'Error invoking tool ${tool.name} with args $args: ',
                exception,
                stack,
              );
              return {
                'error': 'Tool ${tool.name} failed to execute: $exception',
              };
            }
          },
        ),
      );
    }

    return dartanticTools;
  }

  Future<Object?> _generate({
    required Iterable<ChatMessage> messages,
    required List<AiTool> availableTools,
    dsb.Schema? outputSchema,
  }) async {
    final converter = DartanticContentConverter();
    final adapter = DartanticSchemaAdapter();

    // Convert messages to dartantic format
    final dartanticMessages = converter.toDartanticMessages(messages);

    // Set up tools
    final dartanticTools = _setupTools(
      availableTools: availableTools,
      adapter: adapter,
      outputSchema: outputSchema,
    );

    // Create agent with tools
    final agent = agentFactory(
      provider: provider,
      model: model,
      tools: dartanticTools,
    );

    if (outputSchema != null) {
      // Use structured output
      final adaptedSchema = adapter.adapt(outputSchema);
      if (adaptedSchema.schema == null) {
        throw AiClientException(
          'Failed to adapt output schema: ${adaptedSchema.errors.join(', ')}',
        );
      }

      try {
        final result = await agent.sendFor(
          dartanticMessages.last.text,
          history: dartanticMessages
              .take(dartanticMessages.length - 1)
              .toList(),
          outputSchema: adaptedSchema.schema!,
        );

        // Update token usage if available
        if (result.usage != null) {
          inputTokenUsage += result.usage!.promptTokens ?? 0;
          outputTokenUsage += result.usage!.responseTokens ?? 0;
        }

        return result.output;
      } catch (e) {
        throw AiClientException('Failed to generate structured content: $e');
      }
    } else {
      // Use text generation
      try {
        final result = await agent.send(
          dartanticMessages.last.text,
          history: dartanticMessages
              .take(dartanticMessages.length - 1)
              .toList(),
        );

        // Update token usage if available
        if (result.usage != null) {
          inputTokenUsage += result.usage!.promptTokens ?? 0;
          outputTokenUsage += result.usage!.responseTokens ?? 0;
        }

        return result.output;
      } catch (e) {
        throw AiClientException('Failed to generate text: $e');
      }
    }
  }
}

/// Logger for this package.
final _logger = Logger('flutter_genui_dartantic');
