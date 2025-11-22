// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart' hide TextPart;
// ignore: implementation_imports

import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart' hide Part;

import 'gemini_content_converter.dart';
import 'gemini_generative_model.dart';
import 'gemini_schema_adapter.dart';

/// A factory for creating a [GeminiGenerativeModelInterface].
///
/// This is used to allow for custom model creation, for example, for testing.
typedef GenerativeModelFactory =
    GeminiGenerativeModelInterface Function({
      required FirebaseAiContentGenerator configuration,
      Content? systemInstruction,
      List<Tool>? tools,
      ToolConfig? toolConfig,
    });

/// A [ContentGenerator] that uses the Firebase AI API to generate content.
///
/// This generator utilizes a [GeminiGenerativeModelInterface] to interact with
/// the Firebase AI API. The actual model instance is created by the
/// [modelCreator] function, which defaults to [defaultGenerativeModelFactory].
class FirebaseAiContentGenerator implements ContentGenerator {
  /// Creates a [FirebaseAiContentGenerator] instance with specified
  /// configurations.
  FirebaseAiContentGenerator({
    required this.catalog,
    this.systemInstruction,
    this.modelCreator = defaultGenerativeModelFactory,
    this.configuration = const GenUiConfiguration(),
    this.additionalTools = const [],
  });

  final GenUiConfiguration configuration;

  /// The catalog of UI components available to the AI.
  final Catalog catalog;

  /// The system instruction to use for the AI model.
  final String? systemInstruction;

  /// A function to use for creating the model itself.
  ///
  /// This factory function is responsible for instantiating the
  /// [GeminiGenerativeModelInterface] used for AI interactions. It allows for
  /// customization of the model setup, such as using different HTTP clients, or
  /// for providing mock models during testing. The factory receives this
  /// [FirebaseAiContentGenerator] instance as configuration.
  ///
  /// Defaults to a wrapper for the regular [GenerativeModel] constructor,
  /// [defaultGenerativeModelFactory].
  final GenerativeModelFactory modelCreator;

  /// Additional tools to make available to the AI model.
  final List<AiTool> additionalTools;

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
      await _generate(messages: messages);
    } catch (e, st) {
      genUiLogger.severe('Error generating content', e, st);
      _errorController.add(ContentGeneratorError(e, st));
    } finally {
      _isProcessing.value = false;
    }
  }

  /// The default factory function for creating a [GenerativeModel].
  ///
  /// This function instantiates a standard [GenerativeModel] using the `model`
  /// from the provided [FirebaseAiContentGenerator] `configuration`.
  static GeminiGenerativeModelInterface defaultGenerativeModelFactory({
    required FirebaseAiContentGenerator configuration,
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

    final functionDeclarations = <FunctionDeclaration>[];
    for (final AiTool<JsonMap> tool in uniqueAiToolsByName.values) {
      Schema? adaptedParameters;
      if (tool.parameters != null) {
        final GeminiSchemaAdapterResult result = adapter.adapt(
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
      final Map<String, Schema>? parameters = adaptedParameters?.properties;
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

    final List<Tool>? generativeAiTools = functionDeclarations.isNotEmpty
        ? [Tool.functionDeclarations(functionDeclarations)]
        : null;

    if (generativeAiTools != null) {
      genUiLogger.finest(
        'Tool declarations being sent to the model: '
        '${jsonEncode(generativeAiTools)}',
      );
    }

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

  Future<List<FunctionResponse>> _processFunctionCalls({
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

      final AiTool<JsonMap> aiTool = availableTools.firstWhere(
        (t) => t.name == call.name || t.fullName == call.name,
        orElse: () => throw Exception('Unknown tool ${call.name} called.'),
      );
      Map<String, Object?> toolResult;
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
    return functionResponseParts;
  }

  Future<void> _generate({required Iterable<ChatMessage> messages}) async {
    final converter = GeminiContentConverter();
    final adapter = GeminiSchemaAdapter();

    final List<AiTool<JsonMap>> availableTools = [...additionalTools];

    // A local copy of the incoming messages which is updated with tool results
    // as they are generated.
    final List<Content> mutableContent = converter.toFirebaseAiContent(
      messages,
    );

    final (
      :List<Tool>? generativeAiTools,
      :Set<String> allowedFunctionNames,
    ) = _setupToolsAndFunctions(
      availableTools: availableTools,
      adapter: adapter,
    );

    var toolUsageCycle = 0;
    const maxToolUsageCycles = 40; // Safety break for tool loops

    final String definition = const JsonEncoder.withIndent(
      '  ',
    ).convert(catalog.definition.toJson());
    final GeminiGenerativeModelInterface model = modelCreator(
      configuration: this,
      systemInstruction: Content.system(
        '${systemInstruction ?? ''}\n\n'
        'You have access to the following UI components:\n'
        '$definition\n\n'
        'You must output your response as a stream of JSON objects, one per '
        'line (JSONL). Each line can be either a plain text response or a '
        'structured A2UI message (e.g., createSurface, surfaceUpdate). '
        'Do not wrap the JSON objects in a list or any other structure. '
        'Just output one JSON object per line.',
      ),
      tools: generativeAiTools,
      toolConfig: generativeAiTools == null
          ? null
          : ToolConfig(functionCallingConfig: FunctionCallingConfig.auto()),
    );

    toolLoop:
    while (toolUsageCycle < maxToolUsageCycles) {
      genUiLogger.fine('Starting tool usage cycle ${toolUsageCycle + 1}.');
      toolUsageCycle++;

      final String concatenatedContents = mutableContent
          .map((c) => const JsonEncoder.withIndent('  ').convert(c.toJson()))
          .join('\n');

      genUiLogger.info(
        '''****** Performing Inference ******\n$concatenatedContents
With functions:
  '${allowedFunctionNames.join(', ')}',
  ''',
      );
      final inferenceStartTime = DateTime.now();

      // We use generateContentStream to handle streaming responses
      final Stream<GenerateContentResponse> responseStream = model
          .generateContentStream(mutableContent);

      final currentLineBuffer = StringBuffer();

      await for (final GenerateContentResponse response in responseStream) {
        if (response.candidates.isEmpty) {
          continue;
        }
        final Candidate candidate = response.candidates.first;

        // Handle function calls if any (though we prefer JSONL now, tools
        // might still be used for other things)
        final List<FunctionCall> functionCalls = candidate.content.parts
            .whereType<FunctionCall>()
            .toList();

        if (functionCalls.isNotEmpty) {
          genUiLogger.fine(
            'Model response contained ${functionCalls.length} function calls.',
          );
          mutableContent.add(candidate.content);
          final List<FunctionResponse> functionResponseParts =
              await _processFunctionCalls(
                functionCalls: functionCalls,
                availableTools: availableTools,
              );

          if (functionResponseParts.isNotEmpty) {
            mutableContent.add(
              Content.functionResponses(functionResponseParts),
            );
            genUiLogger.fine(
              'Added tool response message with '
              '${functionResponseParts.length} parts to conversation.',
            );
            // Continue the loop to send tool outputs back to the model
            continue toolLoop;
          }
        }

        // Handle text content for JSONL parsing
        final String? text = candidate.text;
        if (text != null && text.isNotEmpty) {
          for (var i = 0; i < text.length; i++) {
            final String char = text[i];
            if (char == '\n') {
              _processLine(currentLineBuffer.toString());
              currentLineBuffer.clear();
            } else {
              currentLineBuffer.write(char);
            }
          }
        }
      }

      // Process any remaining content in the buffer
      if (currentLineBuffer.isNotEmpty) {
        _processLine(currentLineBuffer.toString());
      }

      final Duration elapsed = DateTime.now().difference(inferenceStartTime);
      genUiLogger.info(
        '****** Completed Inference ******\n'
        'Latency = ${elapsed.inMilliseconds}ms',
      );

      // If we reached here, it means the stream finished.
      // If there were function calls, the loop would have continued via
      // `continue`. If there were no function calls, we are done.
      break;
    }
  }

  void _processLine(String line) {
    line = line.trim();
    if (line.isEmpty) return;

    try {
      final dynamic json = jsonDecode(line);
      if (json is Map<String, Object?>) {
        // Check if it's an A2UI message
        // We can try to parse it as an A2uiMessage, or check for specific keys
        // Ideally A2uiMessage.fromJson would handle it or throw
        try {
          final message = A2uiMessage.fromJson(json);
          _a2uiMessageController.add(message);
          return;
        } catch (_) {
          // Not an A2UI message, treat as text/other JSON
        }
      }
    } catch (_) {
      // Not JSON, treat as text
    }
    _textResponseController.add(line);
  }
}
