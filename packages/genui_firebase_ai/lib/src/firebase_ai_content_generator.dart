// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart' hide TextPart;
// ignore: implementation_imports
import 'package:firebase_ai/src/api.dart' show ModalityTokenCount;
import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart' hide Part;
import 'package:json_schema_builder/json_schema_builder.dart' as dsb;

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
    this.outputToolName = 'provideFinalOutput',
    this.modelCreator = defaultGenerativeModelFactory,
    this.additionalTools = const [],
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
    A2UiClientCapabilities? clientCapabilities,
  }) async {
    _isProcessing.value = true;
    try {
      final messages = [...?history, message];
      final Object? response = await _generate(
        messages: messages,
        // This turns on forced function calling.
        outputSchema: dsb.S.object(properties: {'response': dsb.S.string()}),
      );
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
    return (
      functionResponseParts: functionResponseParts,
      capturedResult: capturedResult,
    );
  }

  Future<Object?> _generate({
    required Iterable<ChatMessage> messages,
    dsb.Schema? outputSchema,
  }) async {
    final isForcedToolCalling = outputSchema != null;
    final converter = GeminiContentConverter();
    final adapter = GeminiSchemaAdapter();

    final List<AiTool<JsonMap>> availableTools = [
      SurfaceUpdateTool(
        handleMessage: _a2uiMessageController.add,
        catalog: catalog,
      ),
      BeginRenderingTool(
        handleMessage: _a2uiMessageController.add,
        catalogId: catalog.catalogId,
      ),
      DeleteSurfaceTool(handleMessage: _a2uiMessageController.add),
      ...additionalTools,
    ];

    // A local copy of the incoming messages which is updated with tool results
    // as they are generated.
    final List<Content> mutableContent = converter.toFirebaseAiContent(
      messages,
    );

    final (
      :List<Tool>? generativeAiTools,
      :Set<String> allowedFunctionNames,
    ) = _setupToolsAndFunctions(
      isForcedToolCalling: isForcedToolCalling,
      availableTools: availableTools,
      adapter: adapter,
      outputSchema: outputSchema,
    );

    var toolUsageCycle = 0;
    const maxToolUsageCycles = 40; // Safety break for tool loops
    Object? capturedResult;

    final GeminiGenerativeModelInterface model = modelCreator(
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
      GenerateContentResponse response;

      response = await model.generateContent(mutableContent);
      genUiLogger.finest('Raw model response: ${_responseToString(response)}');

      final Duration elapsed = DateTime.now().difference(inferenceStartTime);

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

      final Candidate candidate = response.candidates.first;
      final List<FunctionCall> functionCalls = candidate.content.parts
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
          final String text = candidate.text ?? '';
          mutableContent.add(candidate.content);
          genUiLogger.fine('Returning text response: "$text"');
          _textResponseController.add(text);
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

      final ({
        Object? capturedResult,
        List<FunctionResponse> functionResponseParts,
      })
      result = await _processFunctionCalls(
        functionCalls: functionCalls,
        isForcedToolCalling: isForcedToolCalling,
        availableTools: availableTools,
        capturedResult: capturedResult,
      );
      capturedResult = result.capturedResult;
      final List<FunctionResponse> functionResponseParts =
          result.functionResponseParts;

      if (functionResponseParts.isNotEmpty) {
        mutableContent.add(Content.functionResponses(functionResponseParts));
        genUiLogger.fine(
          'Added tool response message with ${functionResponseParts.length} '
          'parts to conversation.',
        );
      }

      // If the model returned a text response, we assume it's the final
      // response and we should stop the tool calling loop.
      if (!isForcedToolCalling &&
          candidate.text != null &&
          candidate.text!.trim().isNotEmpty) {
        genUiLogger.fine(
          'Model returned a text response of "${candidate.text!.trim()}". '
          'Exiting tool loop.',
        );
        _textResponseController.add(candidate.text!);
        return candidate.text;
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

String _usageMetadata(UsageMetadata? metadata) {
  if (metadata == null) return '';
  final buffer = StringBuffer();
  buffer.writeln('UsageMetadata(');
  buffer.writeln('  promptTokenCount: ${metadata.promptTokenCount},');
  buffer.writeln('  candidatesTokenCount: ${metadata.candidatesTokenCount},');
  buffer.writeln('  totalTokenCount: ${metadata.totalTokenCount},');
  buffer.writeln('  thoughtsTokenCount: ${metadata.thoughtsTokenCount},');
  buffer.writeln(
    '  toolUsePromptTokenCount: ${metadata.toolUsePromptTokenCount},',
  );
  buffer.writeln('  promptTokensDetails: [');
  for (final ModalityTokenCount detail
      in metadata.promptTokensDetails ?? <ModalityTokenCount>[]) {
    buffer.writeln('    ModalityTokenCount(');
    buffer.writeln('      modality: ${detail.modality},');
    buffer.writeln('      tokenCount: ${detail.tokenCount},');
    buffer.writeln('    ),');
  }
  buffer.writeln('  ],');
  buffer.writeln('  candidatesTokensDetails: [');
  for (final ModalityTokenCount detail
      in metadata.candidatesTokensDetails ?? <ModalityTokenCount>[]) {
    buffer.writeln('    ModalityTokenCount(');
    buffer.writeln('      ${detail.modality},');
    buffer.writeln('      ${detail.tokenCount},');
    buffer.writeln('    ),');
  }
  buffer.writeln('  ],');
  buffer.writeln('  toolUsePromptTokensDetails: [');
  for (final ModalityTokenCount detail
      in metadata.toolUsePromptTokensDetails ?? <ModalityTokenCount>[]) {
    buffer.writeln('    ModalityTokenCount(');
    buffer.writeln('      ${detail.modality},');
    buffer.writeln('      ${detail.tokenCount},');
    buffer.writeln('    ),');
  }
  buffer.writeln('  ],');
  buffer.writeln(')');
  return buffer.toString();
}

String _responseToString(GenerateContentResponse response) {
  final buffer = StringBuffer();
  buffer.writeln('GenerateContentResponse(');
  buffer.writeln('  usageMetadata: ${_usageMetadata(response.usageMetadata)},');
  buffer.writeln('  promptFeedback: ${response.promptFeedback},');
  buffer.writeln('  candidates: [');
  for (final Candidate candidate in response.candidates) {
    buffer.writeln('    Candidate(');
    buffer.writeln('      finishReason: ${candidate.finishReason},');
    buffer.writeln('      finishMessage: "${candidate.finishMessage}",');
    buffer.writeln('      content: Content(');
    buffer.writeln('        role: "${candidate.content.role}",');
    buffer.writeln('        parts: [');
    for (final Part part in candidate.content.parts) {
      if (part is TextPart) {
        buffer.writeln(
          '          TextPart(text: "${(part as TextPart).text}"),',
        );
      } else if (part is FunctionCall) {
        buffer.writeln('          FunctionCall(');
        buffer.writeln('            name: "${part.name}",');
        final String indentedLines = (const JsonEncoder.withIndent(
          '  ',
        ).convert(part.args)).split('\n').join('\n            ');
        buffer.writeln('            args: $indentedLines,');
        buffer.writeln('          ),');
      } else {
        buffer.writeln('          Unknown Part: ${part.runtimeType},');
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
