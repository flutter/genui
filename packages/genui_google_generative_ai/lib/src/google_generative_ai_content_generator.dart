// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';
import 'package:google_cloud_ai_generativelanguage_v1beta/generativelanguage.dart'
    as google_ai;
import 'package:google_cloud_protobuf/protobuf.dart' as protobuf;

import 'google_content_converter.dart';
import 'google_generative_service_interface.dart';
import 'google_schema_adapter.dart';

/// A factory for creating a [GoogleGenerativeServiceInterface].
///
/// This is used to allow for custom service creation, for example, for testing.
typedef GenerativeServiceFactory =
    GoogleGenerativeServiceInterface Function({
      required GoogleGenerativeAiContentGenerator configuration,
    });

/// A [ContentGenerator] that uses the Google Cloud Generative Language API to
/// generate content.
class GoogleGenerativeAiContentGenerator implements ContentGenerator {
  /// Creates a [GoogleGenerativeAiContentGenerator] instance with specified
  /// configurations.
  GoogleGenerativeAiContentGenerator({
    required this.catalog,
    this.systemInstruction,
    this.serviceFactory = defaultGenerativeServiceFactory,
    this.additionalTools = const [],
    this.modelName = 'models/gemini-2.5-flash',
    this.apiKey,
  });

  /// The catalog of UI components available to the AI.
  final Catalog catalog;

  /// The system instruction to use for the AI model.
  final String? systemInstruction;

  /// A function to use for creating the service itself.
  ///
  /// This factory function is responsible for instantiating the
  /// [GoogleGenerativeServiceInterface] used for AI interactions. It allows for
  /// customization of the service setup, or for providing mock services during
  /// testing. The factory receives this [GoogleGenerativeAiContentGenerator]
  /// instance as configuration.
  ///
  /// Defaults to a wrapper for the regular [google_ai.GenerativeService]
  /// constructor, [defaultGenerativeServiceFactory].
  final GenerativeServiceFactory serviceFactory;

  /// Additional tools to make available to the AI model.
  final List<AiTool> additionalTools;

  /// The model name to use (e.g., 'models/gemini-2.5-flash').
  final String modelName;

  /// The API key to use for authentication.
  final String? apiKey;

  /// The total number of input tokens used by this client.
  int inputTokenUsage = 0;

  /// The total number of output tokens used by this client
  int outputTokenUsage = 0;

  final _a2uiMessageController = StreamController<A2uiMessage>.broadcast();
  final _textResponseController = StreamController<String>.broadcast();
  final _errorController = StreamController<ContentGeneratorError>.broadcast();
  final _isProcessing = ValueNotifier<bool>(false);

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
      final messages = [...?history, message];
      await _generate(messages: messages);
    } catch (e, st) {
      genUiLogger.severe('Error generating content', e, st);
      _errorController.add(ContentGeneratorError(e, st));
    } finally {
      _isProcessing.value = false;
    }
  }

  /// The default factory function for creating a [google_ai.GenerativeService].
  ///
  /// This function instantiates a standard [google_ai.GenerativeService] using
  /// the `apiKey` from the provided [GoogleGenerativeAiContentGenerator]
  /// `configuration`.
  static GoogleGenerativeServiceInterface defaultGenerativeServiceFactory({
    required GoogleGenerativeAiContentGenerator configuration,
  }) {
    return GoogleGenerativeServiceWrapper(
      google_ai.GenerativeService.fromApiKey(configuration.apiKey),
    );
  }

  ({List<google_ai.Tool>? tools, Set<String> allowedFunctionNames})
  _setupToolsAndFunctions({
    required List<AiTool> availableTools,
    required GoogleSchemaAdapter adapter,
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
    for (final tool in uniqueAiToolsByName.values) {
      google_ai.Schema? adaptedParameters;
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

    final tools = functionDeclarations.isNotEmpty
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

  Future<({List<google_ai.Part> functionResponseParts})> _processFunctionCalls({
    required List<google_ai.FunctionCall> functionCalls,
    required List<AiTool> availableTools,
  }) async {
    genUiLogger.fine(
      'Processing ${functionCalls.length} function calls from model.',
    );
    final functionResponseParts = <google_ai.Part>[];
    for (final call in functionCalls) {
      genUiLogger.fine(
        'Processing function call: ${call.name} with args: ${call.args}',
      );

      final aiTool = availableTools.firstWhere(
        (t) => t.name == call.name || t.fullName == call.name,
        orElse: () => throw Exception('Unknown tool ${call.name} called.'),
      );
      Map<String, Object?> toolResult;
      try {
        genUiLogger.fine('Invoking tool: ${aiTool.name}');
        // Convert Struct args to Map for tool invocation
        final argsMap = call.args?.toJson() as Map<String, Object?>? ?? {};
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
      functionResponseParts.add(
        google_ai.Part(
          functionResponse: google_ai.FunctionResponse(
            id: call.id,
            name: call.name!,
            response: protobuf.Struct.fromJson(toolResult),
          ),
        ),
      );
    }
    genUiLogger.fine(
      'Finished processing function calls. Returning '
      '${functionResponseParts.length} responses.',
    );
    return (functionResponseParts: functionResponseParts);
  }

  Future<void> _generate({required Iterable<ChatMessage> messages}) async {
    final converter = GoogleContentConverter();
    final adapter = GoogleSchemaAdapter();

    final service = serviceFactory(configuration: this);

    try {
      // A local copy of the incoming messages which is updated with
      // tool results
      // as they are generated.
      final content = converter.toGoogleAiContent(messages);

      final (:tools, :allowedFunctionNames) = _setupToolsAndFunctions(
        availableTools: additionalTools,
        adapter: adapter,
      );

      var toolUsageCycle = 0;
      const maxToolUsageCycles = 40; // Safety break for tool loops

      // Build system instruction if provided
      final definition = const JsonEncoder.withIndent(
        '  ',
      ).convert(catalog.definition.toJson());
      final effectiveSystemInstruction =
          '${systemInstruction ?? ''}\n\n'
          'You have access to the following UI components:\n'
          '$definition\n\n'
          'You must output your response as a stream of JSON objects, one per '
          'line (JSONL). Each line can be either a plain text response or a '
          'structured A2UI message (e.g., createSurface, surfaceUpdate). '
          'Do not wrap the JSON objects in a list or any other structure. '
          'Just output one JSON object per line.';

      final systemInstructionContent = [
        google_ai.Content(
          parts: [google_ai.Part(text: effectiveSystemInstruction)],
        ),
      ];

      toolLoop:
      while (toolUsageCycle < maxToolUsageCycles) {
        genUiLogger.fine('Starting tool usage cycle ${toolUsageCycle + 1}.');
        toolUsageCycle++;

        final concatenatedContents = content
            .map((c) => jsonEncode(c.toJson()))
            .join('\n');

        genUiLogger.info(
          '''****** Performing Inference ******\n$concatenatedContents
With functions:
  '${allowedFunctionNames.join(', ')}',
  ''',
        );
        final inferenceStartTime = DateTime.now();

        final request = google_ai.GenerateContentRequest(
          model: modelName,
          contents: [...systemInstructionContent, ...content],
          tools: tools,
          toolConfig: tools == null
              ? null
              : google_ai.ToolConfig(
                  functionCallingConfig: google_ai.FunctionCallingConfig(
                    mode: google_ai.FunctionCallingConfig_Mode.auto,
                  ),
                ),
        );

        final responseStream = service.streamGenerateContent(request);

        final currentLineBuffer = StringBuffer();

        await for (final google_ai.GenerateContentResponse response
            in responseStream) {
          if (response.candidates == null || response.candidates!.isEmpty) {
            continue;
          }

          final candidate = response.candidates!.first;
          genUiLogger.fine(
            'Received candidate: content=${candidate.content}, '
            'finishReason=${candidate.finishReason}, '
            'safetyRatings=${candidate.safetyRatings}',
          );

          // Handle function calls
          final functionCalls = <google_ai.FunctionCall>[];
          if (candidate.content?.parts != null) {
            for (final part in candidate.content!.parts!) {
              if (part.functionCall != null) {
                functionCalls.add(part.functionCall!);
              }
            }
          }

          if (functionCalls.isNotEmpty) {
            genUiLogger.fine(
              'Model response contained ${functionCalls.length} '
              'function calls.',
            );
            if (candidate.content != null) {
              content.add(candidate.content!);
            }

            final result = await _processFunctionCalls(
              functionCalls: functionCalls,
              availableTools: additionalTools,
            );
            final functionResponseParts = result.functionResponseParts;

            if (functionResponseParts.isNotEmpty) {
              content.add(
                google_ai.Content(role: 'user', parts: functionResponseParts),
              );
              genUiLogger.fine(
                'Added tool response message with '
                '${functionResponseParts.length} parts to conversation.',
              );
              continue toolLoop;
            }
          }

          // Handle text content for JSONL parsing
          if (candidate.content?.parts != null) {
            for (final part in candidate.content!.parts!) {
              final text = part.text;
              if (text != null && text.isNotEmpty) {
                genUiLogger.fine('Received text part: $text');
                for (var i = 0; i < text.length; i++) {
                  final char = text[i];
                  if (char == '\n') {
                    _processLine(currentLineBuffer.toString());
                    currentLineBuffer.clear();
                  } else {
                    currentLineBuffer.write(char);
                  }
                }
              }
            }
          }
        }

        // Process any remaining content in the buffer
        if (currentLineBuffer.isNotEmpty) {
          _processLine(currentLineBuffer.toString());
        }

        final elapsed = DateTime.now().difference(inferenceStartTime);
        genUiLogger.info(
          '****** Completed Inference ******\n'
          'Latency = ${elapsed.inMilliseconds}ms',
        );

        // If we reached here, it means the stream finished.
        // If there were function calls, the loop would have continued via
        // `continue toolLoop`. If there were no function calls, we are done.
        break;
      }
    } finally {
      service.close();
    }
  }

  void _processLine(String line) {
    line = line.trim();
    // Strip markdown code block delimiters
    if (line.startsWith('```')) {
      line = line.replaceFirst(RegExp(r'^```[a-zA-Z]*'), '');
    }
    if (line.endsWith('```')) {
      line = line.substring(0, line.length - 3);
    }
    line = line.trim();

    if (line.isEmpty) {
      return;
    }

    // If the line doesn't start with '{', it's not a JSONL object.
    if (!line.startsWith('{')) {
      genUiLogger.fine('Ignored non-JSONL line: $line');
      return;
    }

    genUiLogger.fine('Processing line: $line');

    try {
      final json = jsonDecode(line);
      if (json is Map<String, dynamic>) {
        try {
          final message = A2uiMessage.fromJson(json);
          genUiLogger.fine('Parsed A2UI message: $message');
          _a2uiMessageController.add(message);
          return;
        } catch (e) {
          // Not an A2UI message, treat as text/other JSON
          genUiLogger.fine('Failed to parse as A2UI message: $e');
        }
      }
    } catch (e) {
      // Not JSON, treat as text
      genUiLogger.fine('Failed to parse as JSON: $e');
    }
    _textResponseController.add(line);
  }
}
