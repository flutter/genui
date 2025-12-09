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
    this.outputToolName = 'provideFinalOutput',
    this.serviceFactory = defaultGenerativeServiceFactory,
    this.additionalTools = const [],
    this.modelName = 'models/gemini-2.5-flash',
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
  }) async {
    _isProcessing.value = true;
    try {
      final messages = [...?history, message];
      final response = await _generate(messages: messages);
      // Convert any response to a text response to the user.
      if (response is Map && response.containsKey('response')) {
        _textResponseController.add(response['response']! as String);
      }
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
    genUiLogger.fine(
      'Available tools: ${availableTools.map((t) => t.name).join(', ')}',
    );

    final uniqueAiToolsByName = <String, AiTool>{};
    final toolFullNames = <String>{};
    for (final tool in availableTools) {
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

  Future<({List<google_ai.Part> functionResponseParts, Object? capturedResult})>
  _processFunctionCalls({
    required List<google_ai.FunctionCall> functionCalls,
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
    return (
      functionResponseParts: functionResponseParts,
      capturedResult: capturedResult,
    );
  }

  Future<Object?> _generate({required Iterable<ChatMessage> messages}) async {
    final converter = GoogleContentConverter();
    final adapter = GoogleSchemaAdapter();

    final service = serviceFactory(configuration: this);

    try {
      final availableTools = [
        SurfaceUpdateTool(
          handleMessage: _a2uiMessageController.add,
          catalog: catalog,
        ),
        BeginRenderingTool(handleMessage: _a2uiMessageController.add),

        DeleteSurfaceTool(handleMessage: _a2uiMessageController.add),
      ];

      // A local copy of the incoming messages which is updated with
      // tool results
      // as they are generated.
      final content = converter.toGoogleAiContent(messages);

      final (:tools, :allowedFunctionNames) = _setupToolsAndFunctions(
        availableTools: availableTools,
        adapter: adapter,
      );

      var toolUsageCycle = 0;
      const maxToolUsageCycles = 40; // Safety break for tool loops
      Object? capturedResult;

      // Build system instruction if provided
      final systemInstructionContent = systemInstruction != null
          ? [
              google_ai.Content(
                parts: [google_ai.Part(text: systemInstruction)],
              ),
            ]
          : <google_ai.Content>[];

      while (toolUsageCycle < maxToolUsageCycles) {
        genUiLogger.fine('Starting tool usage cycle ${toolUsageCycle + 1}.');
        if (capturedResult != null) {
          genUiLogger.fine('Captured result found, exiting tool usage loop.');
          break;
        }
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
        google_ai.GenerateContentResponse response;
        try {
          final request = google_ai.GenerateContentRequest(
            model: modelName,
            contents: [...systemInstructionContent, ...content],
            tools: tools,
            toolConfig: google_ai.ToolConfig(
              functionCallingConfig: google_ai.FunctionCallingConfig(
                mode: google_ai.FunctionCallingConfig_Mode.auto,
              ),
            ),
          );
          response = await service.generateContent(request);
          genUiLogger.finest(
            'Raw model response: ${_responseToString(response)}',
          );
        } catch (e, st) {
          genUiLogger.severe('Error from service.generateContent', e, st);
          _errorController.add(ContentGeneratorError(e, st));
          rethrow;
        }
        final elapsed = DateTime.now().difference(inferenceStartTime);

        if (response.usageMetadata != null) {
          inputTokenUsage += (response.usageMetadata!.promptTokenCount ?? 0)
              .toInt();
          outputTokenUsage +=
              (response.usageMetadata!.candidatesTokenCount ?? 0).toInt();
        }
        genUiLogger.info(
          '****** Completed Inference ******\n'
          'Latency = ${elapsed.inMilliseconds}ms\n'
          'Output tokens = '
          '${response.usageMetadata?.candidatesTokenCount ?? 0}\n'
          'Prompt tokens = ${response.usageMetadata?.promptTokenCount ?? 0}',
        );

        if (response.candidates == null || response.candidates!.isEmpty) {
          genUiLogger.warning(
            'Response has no candidates: ${response.promptFeedback}',
          );
          return '';
        }

        final candidate = response.candidates!.first;
        final functionCalls = <google_ai.FunctionCall>[];
        if (candidate.content?.parts != null) {
          for (final part in candidate.content!.parts!) {
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
            final textParts = candidate.content!.parts!
                .where((google_ai.Part p) => p.text != null)
                .map((google_ai.Part p) => p.text!)
                .toList();
            text = textParts.join('');
          }
          if (candidate.content != null) {
            content.add(candidate.content!);
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
          '${candidate.content?.parts?.length ?? 0} '
          'parts to conversation.',
        );

        final result = await _processFunctionCalls(
          functionCalls: functionCalls,
          availableTools: availableTools,
          capturedResult: capturedResult,
        );
        capturedResult = result.capturedResult;
        final functionResponseParts = result.functionResponseParts;

        if (functionResponseParts.isNotEmpty) {
          content.add(
            google_ai.Content(role: 'user', parts: functionResponseParts),
          );
          genUiLogger.fine(
            'Added tool response message with ${functionResponseParts.length} '
            'parts to conversation.',
          );
        }

        // If the model returned a text response, we assume it's the final
        // response and we should stop the tool calling loop.
        if (candidate.content?.parts != null) {
          final textParts = candidate.content!.parts!
              .where((google_ai.Part p) => p.text != null)
              .map((google_ai.Part p) => p.text!)
              .toList();
          final text = textParts.join('');
          if (text.trim().isNotEmpty) {
            genUiLogger.fine(
              'Model returned a text response of "${text.trim()}". '
              'Exiting tool loop.',
            );
            _textResponseController.add(text);
            return text;
          }
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
  if (response.candidates != null) {
    for (final candidate in response.candidates!) {
      buffer.writeln('    Candidate(');
      buffer.writeln('      finishReason: ${candidate.finishReason},');
      buffer.writeln('      finishMessage: "${candidate.finishMessage}",');
      buffer.writeln('      content: Content(');
      buffer.writeln('        role: "${candidate.content?.role}",');
      buffer.writeln('        parts: [');
      if (candidate.content?.parts != null) {
        for (final part in candidate.content!.parts!) {
          if (part.text != null) {
            buffer.writeln('          Part(text: "${part.text}"),');
          } else if (part.functionCall != null) {
            buffer.writeln('          Part(functionCall:');
            buffer.writeln('            FunctionCall(');
            buffer.writeln('              name: "${part.functionCall!.name}",');
            final indentedLines = (const JsonEncoder.withIndent('  ').convert(
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
  }
  buffer.writeln('  ],');
  buffer.writeln(')');
  return buffer.toString();
}
