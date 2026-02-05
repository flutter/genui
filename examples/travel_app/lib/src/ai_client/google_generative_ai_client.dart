// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';
import 'package:genui/parsing.dart';
import 'package:google_cloud_ai_generativelanguage_v1beta/generativelanguage.dart'
    as google_ai;
import 'package:google_cloud_protobuf/protobuf.dart' as protobuf;
import 'package:json_schema_builder/json_schema_builder.dart' as dsb;

import 'ai_client.dart';
import 'google_content_converter.dart';
import 'google_generative_service_interface.dart';
import 'google_schema_adapter.dart';
import 'tools.dart';

/// A factory for creating a [GoogleGenerativeServiceInterface].
///
/// This is used to allow for custom service creation, for example, for testing.
typedef GenerativeServiceFactory =
    GoogleGenerativeServiceInterface Function({
      required GoogleGenerativeAiClient configuration,
    });

/// A client that uses the Google Cloud Generative Language API to
/// generate content.
class GoogleGenerativeAiClient implements AiClient {
  /// Creates a [GoogleGenerativeAiClient] instance with specified
  /// configurations.
  ///
  /// The [catalog] is the registry of components that can be dynamically
  /// rendered.
  ///
  /// [systemInstruction] is an optional instruction to guide the model's
  /// behavior.
  ///
  /// [outputToolName] allows customizing the name of the internal tool used for
  /// final output. Defaults to 'provideFinalOutput'.
  ///
  /// [serviceFactory] is an optional factory for creating the
  /// [GoogleGenerativeServiceInterface].
  ///
  /// [additionalTools] allows providing extra [AiTool]s to the model.
  ///
  /// [modelName] is the name of the model to use (e.g., 'models/gemini-pro').
  ///
  /// [apiKey] is the API key to use for authentication.
  GoogleGenerativeAiClient({
    required this.catalog,
    this.systemInstruction,
    this.outputToolName = 'provideFinalOutput',
    this.serviceFactory = defaultGenerativeServiceFactory,
    this.additionalTools = const [],
    this.modelName = 'models/gemini-3-flash',
    this.apiKey,
  });

  /// The catalog of UI components available to the AI.
  final Catalog catalog;

  /// The system instruction to use for the AI model.
  final String? systemInstruction;

  /// The name of an internal pseudo-tool used to retrieve the final structured
  /// output from the AI.
  ///
  /// This only needs to be provided in case of name collision with another
  /// tool.
  ///
  /// Defaults to 'provideFinalOutput'.
  final String outputToolName;

  /// A function to use for creating the service itself.
  ///
  /// This factory function is responsible for instantiating the
  /// [GoogleGenerativeServiceInterface] used for AI interactions. It allows for
  /// customization of the service setup, or for providing mock services during
  /// testing. The factory receives this [GoogleGenerativeAiClient]
  /// instance as configuration.
  ///
  /// Defaults to a wrapper for the regular [google_ai.GenerativeService]
  /// constructor, [defaultGenerativeServiceFactory].
  final GenerativeServiceFactory serviceFactory;

  /// Additional tools to make available to the AI model.
  final List<AiTool> additionalTools;

  /// The model name to use (e.g., 'models/gemini-3-flash').
  final String modelName;

  /// The API key to use for authentication.
  final String? apiKey;

  /// The total number of input tokens used by this client.
  int inputTokenUsage = 0;

  /// The total number of output tokens used by this client
  /// The total number of output tokens used by this client
  int outputTokenUsage = 0;

  final _a2uiMessageController = StreamController<A2uiMessage>.broadcast();
  final _textResponseController = StreamController<String>.broadcast();
  final _eventController = StreamController<GenerationEvent>.broadcast();
  final _errorController = StreamController<Object>.broadcast();
  final _isProcessing = ValueNotifier<bool>(false);

  /// A stream of A2UI messages produced by the generator.
  @override
  Stream<A2uiMessage> get a2uiMessageStream => _a2uiMessageController.stream;

  /// A stream of text responses from the agent.
  @override
  Stream<String> get textResponseStream => _textResponseController.stream;

  /// A stream of errors from the agent.
  Stream<Object> get errorStream => _errorController.stream;

  /// A stream of events related to the generation process (tool calls, usage,
  /// etc.).
  Stream<GenerationEvent> get eventStream => _eventController.stream;

  /// Whether the content generator is currently processing a request.
  ValueListenable<bool> get isProcessing => _isProcessing;

  @override
  void dispose() {
    _a2uiMessageController.close();
    _textResponseController.close();
    _eventController.close();
    _errorController.close();
    _isProcessing.dispose();
  }

  void emitEvent(GenerationEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  /// Sends a request to the AI model.
  ///
  /// Note: [clientDataModel] is currently ignored by this implementation.
  @override
  Future<void> sendRequest(
    ChatMessage message, {
    Iterable<ChatMessage>? history,
    A2UiClientCapabilities? clientCapabilities,
    Map<String, Object?>? clientDataModel,
    CancellationSignal? cancellationSignal,
  }) async {
    _isProcessing.value = true;
    try {
      // TODO: Include clientDataModel in the request/prompt if needed.
      final messages = [...?history, message];
      final Object? response = await _generate(
        messages: messages,
        cancellationSignal: cancellationSignal,
      );

      if (response != null) {
        if (response is Map<String, Object?>) {
          // If we got a JSON object, it might be an A2UI message or just
          // context. For now, we assume A2UI messages are emitted via the
          // controller during parsing in _generate, but if the return value is
          // just the object, we might want to check it. However, _generate now
          // returns the *text* or the *result*. Let's assume _generate handles
          // emitting A2UI messages.
        }
      }
    } on CancellationException {
      genUiLogger.info('Request cancelled');
    } catch (e, st) {
      genUiLogger.severe('Error generating content', e, st);
      _errorController.add(e);
    } finally {
      _isProcessing.value = false;
    }
  }

  /// The default factory function for creating a [google_ai.GenerativeService].
  ///
  /// This function instantiates a standard [google_ai.GenerativeService] using
  /// the `apiKey` from the provided [GoogleGenerativeAiClient]
  /// `configuration`.
  static GoogleGenerativeServiceInterface defaultGenerativeServiceFactory({
    required GoogleGenerativeAiClient configuration,
  }) {
    return GoogleGenerativeServiceWrapper(
      google_ai.GenerativeService.fromApiKey(configuration.apiKey),
    );
  }

  ({List<google_ai.Tool>? tools, Set<String> allowedFunctionNames})
  _setupToolsAndFunctions({
    required bool isForcedToolCalling,
    required List<AiTool> availableTools,
    required GoogleSchemaAdapter adapter,
    required dsb.Schema? outputSchema,
  }) {
    genUiLogger.fine(
      'Setting up tools'
      '${isForcedToolCalling ? ' with forced tool calling' : ''}',
    );
    // Create an "output" tool that copies its args into the output.
    final DynamicAiTool<Map<String, Object?>>? finalOutputAiTool =
        isForcedToolCalling
        ? DynamicAiTool<Map<String, Object?>>(
            name: outputToolName,
            description:
                '''Returns the final output. Call this function when you are done with the current turn of the conversation. Do not call this if you need to use other tools first. You MUST call this tool when you are done.''',
            // Wrap the outputSchema in an object so that the output schema
            // isn't limited to objects.
            parameters: dsb.S.object(properties: {'output': outputSchema!}),
            invokeFunction: (args) async => args, // Invoke is a pass-through
          )
        : null;

    final List<AiTool<JsonMap>> allTools = isForcedToolCalling
        ? [...availableTools, finalOutputAiTool!]
        : availableTools;
    genUiLogger.fine(
      'Available tools: ${allTools.map((t) => t.name).join(', ')}',
    );

    final uniqueAiToolsByName = <String, AiTool>{};
    final toolFullNames = <String>{};
    for (final tool in allTools) {
      if (uniqueAiToolsByName.containsKey(tool.name)) {
        throw Exception('Duplicate tool ${tool.name} registered.');
      }
      uniqueAiToolsByName[tool.name] = tool;
      if (tool.name != tool.fullName) {
        if (toolFullNames.contains(tool.fullName)) {
          throw Exception('Duplicate tool ${tool.fullName} registered.');
        }
        toolFullNames.add(tool.fullName);
      }
    }

    final functionDeclarations = <google_ai.FunctionDeclaration>[];
    for (final AiTool<JsonMap> tool in uniqueAiToolsByName.values) {
      google_ai.Schema? adaptedParameters;
      if (tool.parameters != null) {
        final GoogleSchemaAdapterResult result = adapter.adapt(
          tool.parameters!,
        );
        if (result.errors.isNotEmpty) {
          genUiLogger.warning(
            'Errors adapting parameters for tool ${tool.name}: '
            '${result.errors.join('\n')}',
          );
        }
        adaptedParameters = result.schema;
      }
      functionDeclarations.add(
        google_ai.FunctionDeclaration(
          name: tool.name,
          description: tool.description,
          parameters: adaptedParameters,
        ),
      );
      if (tool.name != tool.fullName) {
        functionDeclarations.add(
          google_ai.FunctionDeclaration(
            name: tool.fullName,
            description: tool.description,
            parameters: adaptedParameters,
          ),
        );
      }
    }
    genUiLogger.fine(
      'Adapted tools to function declarations: '
      '${functionDeclarations.map((d) => d.name).join(', ')}',
    );

    final List<google_ai.Tool>? tools = functionDeclarations.isNotEmpty
        ? [google_ai.Tool(functionDeclarations: functionDeclarations)]
        : null;

    if (tools != null) {
      genUiLogger.finest(
        'Tool declarations being sent to the model: '
        '${jsonEncode(tools)}',
      );
    }

    final allowedFunctionNames = <String>{
      ...uniqueAiToolsByName.keys,
      ...toolFullNames,
    };

    genUiLogger.fine(
      'Allowed function names for model: ${allowedFunctionNames.join(', ')}',
    );

    return (tools: tools, allowedFunctionNames: allowedFunctionNames);
  }

  Future<({List<google_ai.Part> functionResponseParts, Object? capturedResult})>
  _processFunctionCalls({
    required List<google_ai.FunctionCall> functionCalls,
    required bool isForcedToolCalling,
    required List<AiTool> availableTools,
    Object? capturedResult,
  }) async {
    genUiLogger.fine(
      'Processing ${functionCalls.length} function calls from model.',
    );
    final functionResponseParts = <google_ai.Part>[];
    for (final call in functionCalls) {
      genUiLogger.fine(
        'Processing function call: ${call.name} with args: ${call.args}',
      );

      // Convert Struct args to Map for easier handling
      final Map<String, Object?> argsMap =
          call.args?.toJson() as Map<String, Object?>? ?? {};

      // Intercept tool call
      // final toolAction = await interceptToolCall(call.name, argsMap);
      // Tool interception removed with ContentGeneratorMixin for now,
      // or needs reimplementation
      // default proceed:
      // if (toolAction is ToolActionCancel) ...

      /*
      if (toolAction is ToolActionCancel) {
        genUiLogger.info('Tool call ${call.name} cancelled by interceptor.');
        // Return an error/cancellation message to the model so it knows what happened.
        functionResponseParts.add(
          google_ai.Part(
            functionResponse: google_ai.FunctionResponse(
              id: call.id,
              name: call.name,
              response: protobuf.Struct.fromJson({
                'error': 'Tool call cancelled by client.',
              }),
            ),
          ),
        );
        continue;
      } else if (toolAction is ToolActionMock) {
        genUiLogger.info(
          'Tool call ${call.name} mocked by interceptor '
          'with result: ${toolAction.result}',
        );
        functionResponseParts.add(
          google_ai.Part(
            functionResponse: google_ai.FunctionResponse(
              id: call.id,
              name: call.name,
              // Ensure result is a Map for Struct conversion if possible,
              // otherwise wrap it or handle it.
              // protobuf.Struct expects Map<String, dynamic>.
              response: protobuf.Struct.fromJson(
                toolAction.result as Map<String, dynamic>,
              ),
            ),
          ),
        );
        continue;
      }
      */

      // ToolActionProceed falls through here

      if (isForcedToolCalling && call.name == outputToolName) {
        try {
          capturedResult = argsMap['output'];
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

      final AiTool<JsonMap> aiTool = availableTools.firstWhere(
        (t) => t.name == call.name || t.fullName == call.name,
        orElse: () => throw Exception('Unknown tool ${call.name} called.'),
      );

      // Emit ToolStartEvent
      emitEvent(ToolStartEvent(toolName: aiTool.name, args: argsMap));

      Map<String, Object?> toolResult;
      final startTime = DateTime.now();
      try {
        genUiLogger.fine('Invoking tool: ${aiTool.name}');
        toolResult = await aiTool.invoke(argsMap);
        genUiLogger.info(
          'Invoked tool ${aiTool.name} with args $argsMap. '
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
      final Duration duration = DateTime.now().difference(startTime);

      // Emit ToolEndEvent
      emitEvent(
        ToolEndEvent(
          toolName: aiTool.name,
          result: toolResult,
          duration: duration,
        ),
      );

      functionResponseParts.add(
        google_ai.Part(
          functionResponse: google_ai.FunctionResponse(
            id: call.id,
            name: call.name,
            response: protobuf.Struct.fromJson(toolResult),
          ),
        ),
      );
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
    CancellationSignal? cancellationSignal,
  }) async {
    final converter = GoogleContentConverter();
    final adapter = GoogleSchemaAdapter();

    final GoogleGenerativeServiceInterface service = serviceFactory(
      configuration: this,
    );

    try {
      // Remove default tools if they are overridden by additionalTools
      final List<AiTool<JsonMap>> availableTools = [...additionalTools];

      // A local copy of the incoming messages which is updated with
      // tool results
      // as they are generated.
      final List<google_ai.Content> content = converter.toGoogleAiContent(
        messages,
      );

      final (
        :List<google_ai.Tool>? tools,
        :Set<String> allowedFunctionNames,
      ) = _setupToolsAndFunctions(
        isForcedToolCalling: false,
        availableTools: availableTools,
        adapter: adapter,
        outputSchema: null,
      );

      var toolUsageCycle = 0;
      const maxToolUsageCycles = 40; // Safety break for tool loops

      // Build system instruction if provided
      final parts = <google_ai.Part>[];
      if (systemInstruction != null) {
        parts.add(google_ai.Part(text: systemInstruction));
      }
      parts.add(
        google_ai.Part(
          text:
              'Current Date: '
              '${DateTime.now().toIso8601String().split('T').first}\n'
              'You do not have the ability to execute code. If you need to '
              'perform calculations, do them yourself.',
        ),
      );
      parts.add(
        google_ai.Part(text: StandardCatalogEmbed.standardCatalogRules),
      );
      final String catalogJson = A2uiMessage.a2uiMessageSchema(
        catalog,
      ).toJson(indent: '  ');
      parts.add(google_ai.Part(text: 'A2UI Message Schema:\n$catalogJson'));

      final systemInstructionContent = parts.isNotEmpty
          ? [google_ai.Content(role: 'user', parts: parts)]
          : <google_ai.Content>[];

      while (toolUsageCycle < maxToolUsageCycles) {
        if (cancellationSignal?.isCancelled ?? false) {
          throw const CancellationException();
        }
        genUiLogger.fine('Starting tool usage cycle ${toolUsageCycle + 1}.');
        toolUsageCycle++;

        final String concatenatedContents = content
            .map((c) => jsonEncode(c.toJson()))
            .join('\n');

        genUiLogger.info(
          '''****** Performing Inference ******\n$concatenatedContents
With functions:
  '${allowedFunctionNames.join(', ')}',
  ''',
        );
        final String instructionText = [
          ...systemInstructionContent,
          ...content,
        ].map((c) => c.parts.map((p) => p.text).join('')).join('\n---\n');
        genUiLogger.fine('Full prompt content: $instructionText');
        final inferenceStartTime = DateTime.now();
        google_ai.GenerateContentResponse response;
        try {
          final request = google_ai.GenerateContentRequest(
            model: modelName,
            contents: [...systemInstructionContent, ...content],
            tools: tools ?? [],
            toolConfig: (tools?.isNotEmpty ?? false)
                ? google_ai.ToolConfig(
                    functionCallingConfig: google_ai.FunctionCallingConfig(
                      mode: google_ai.FunctionCallingConfig_Mode.auto,
                    ),
                  )
                : null,
          );
          response = await service.generateContent(request);
          genUiLogger.finest(
            'Raw model response: ${_responseToString(response)}',
          );
        } catch (e, st) {
          genUiLogger.severe('Error from service.generateContent', e, st);
          _errorController.add(e);
          rethrow;
        }
        final Duration elapsed = DateTime.now().difference(inferenceStartTime);

        if (response.usageMetadata != null) {
          inputTokenUsage += response.usageMetadata!.promptTokenCount;
          outputTokenUsage += response.usageMetadata!.candidatesTokenCount;
          emitEvent(
            TokenUsageEvent(
              inputTokens: response.usageMetadata!.promptTokenCount,
              outputTokens: response.usageMetadata!.candidatesTokenCount,
            ),
          );
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

        final google_ai.Candidate candidate = response.candidates.first;
        final functionCalls = <google_ai.FunctionCall>[];
        if (candidate.content?.parts != null) {
          for (final google_ai.Part part in candidate.content!.parts) {
            if (part.functionCall != null) {
              functionCalls.add(part.functionCall!);
            }
          }
        }

        if (functionCalls.isEmpty) {
          genUiLogger.fine('Model response contained no function calls.');
          // Extract text from parts
          var text = '';
          if (candidate.content?.parts != null) {
            final List<String> textParts = candidate.content!.parts
                .where((google_ai.Part p) => p.text != null)
                .map((google_ai.Part p) => p.text!)
                .toList();
            text = textParts.join('');
          }
          if (candidate.content != null) {
            content.add(candidate.content!);
          }

          // Parse JSON from text.
          final List<dynamic> jsonBlocks = JsonBlockParser.parseJsonBlocks(
            text,
          );
          for (final jsonBlock in jsonBlocks) {
            try {
              if (jsonBlock is Map<String, dynamic>) {
                // The model sometimes omits the version, so we inject it if
                // it's missing.
                if (!jsonBlock.containsKey('version')) {
                  jsonBlock['version'] = 'v0.9';
                }
                final message = A2uiMessage.fromJson(jsonBlock);
                _a2uiMessageController.add(message);
                genUiLogger.info(
                  'Emitted A2UI message from prompt extraction: $message',
                );
              }
            } catch (e) {
              genUiLogger.warning(
                'Failed to parse extracted JSON as A2uiMessage: $e',
              );
            }
          }

          if (jsonBlocks.isNotEmpty) {
            // remove the JSON from the text response
            text = JsonBlockParser.stripJsonBlock(text);
          }

          genUiLogger.fine('Returning text response: "$text"');
          _textResponseController.add(text);
          return text;
        }

        genUiLogger.fine(
          'Model response contained ${functionCalls.length} function calls.',
        );
        if (candidate.content != null) {
          content.add(candidate.content!);
        }
        genUiLogger.fine(
          'Added assistant message with '
          '${candidate.content?.parts.length ?? 0} '
          'parts to conversation.',
        );

        final ({
          Object? capturedResult,
          List<google_ai.Part> functionResponseParts,
        })
        result = await _processFunctionCalls(
          functionCalls: functionCalls,
          isForcedToolCalling: false,
          availableTools: availableTools,
          capturedResult: null,
        );
        final List<google_ai.Part> functionResponseParts =
            result.functionResponseParts;

        if (functionResponseParts.isNotEmpty) {
          content.add(
            google_ai.Content(role: 'user', parts: functionResponseParts),
          );
          genUiLogger.fine(
            'Added tool response message with ${functionResponseParts.length} '
            'parts to conversation.',
          );
        }
      }

      genUiLogger.severe(
        'Error: Tool usage cycle exceeded maximum of $maxToolUsageCycles. ',
        'No final output was produced.',
        StackTrace.current,
      );
      return '';
    } finally {
      service.close();
    }
  }
}

String _responseToString(google_ai.GenerateContentResponse response) {
  final buffer = StringBuffer();
  buffer.writeln('GenerateContentResponse(');
  buffer.writeln('  usageMetadata: ${response.usageMetadata},');
  buffer.writeln('  promptFeedback: ${response.promptFeedback},');
  buffer.writeln('  candidates: [');
  for (final google_ai.Candidate candidate in response.candidates) {
    buffer.writeln('    Candidate(');
    buffer.writeln('      finishReason: ${candidate.finishReason},');
    buffer.writeln('      finishMessage: "${candidate.finishMessage}",');
    buffer.writeln('      content: Content(');
    buffer.writeln('        role: "${candidate.content?.role}",');
    buffer.writeln('        parts: [');
    if (candidate.content?.parts != null) {
      for (final google_ai.Part part in candidate.content!.parts) {
        if (part.text != null) {
          buffer.writeln('          Part(text: "${part.text}"),');
        } else if (part.functionCall != null) {
          buffer.writeln('          Part(functionCall:');
          buffer.writeln('            FunctionCall(');
          buffer.writeln('              name: "${part.functionCall!.name}",');
          final String indentedLines =
              (const JsonEncoder.withIndent('  ').convert(
                part.functionCall!.args ?? {},
              )).split('\n').join('\n              ');
          buffer.writeln('              args: $indentedLines,');
          buffer.writeln('            ),');
          buffer.writeln('          ),');
        } else {
          buffer.writeln('          Unknown Part,');
        }
      }
    }
    buffer.writeln('        ],');
    buffer.writeln('      ),');
    buffer.writeln('    ),');
  }
  buffer.writeln('  ],');
  buffer.writeln(')');
  return buffer.toString();
}
