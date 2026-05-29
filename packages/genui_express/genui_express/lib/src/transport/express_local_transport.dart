// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:genkit/genkit.dart' as genkit;
import 'package:genui/genui.dart';

import '../compiler/express_compiler.dart';

/// A [Transport] implementation that coordinates local Genkit LLM inference
/// streams, maintains session conversation history, and compiles layout DSL
/// outputs.
///
/// Following the Robustness Principle (Postel's Law), it resiliently handles
/// both compact A2UI Express layout DSL blocks (fenced in `<a2ui>`) and
/// standard A2UI JSON specifications (fenced in ```json).
class ExpressLocalTransport implements Transport {
  /// The core Genkit engine instance.
  final genkit.Genkit ai;

  /// The target Genkit model reference.
  final genkit.ModelRef<Object?> model;

  /// The A2UI Express compiler instance.
  final ExpressCompiler compiler;

  /// The component catalog used for property mapping constraints.
  final Catalog catalog;

  final A2uiTransportAdapter _adapter = A2uiTransportAdapter();
  final StreamController<String> _textStreamController =
      StreamController<String>.broadcast();

  final List<ChatMessage> _history = [];
  final StringBuffer _lineBuffer = StringBuffer();
  final List<String> _dslLines = [];
  final List<String> _jsonLines = [];
  bool _insideA2ui = false;
  bool _insideJson = false;

  ExpressLocalTransport({
    required this.ai,
    required this.model,
    required this.catalog,
  }) : compiler = ExpressCompiler(catalog);

  /// Exposes the unmodifiable conversation history list.
  List<ChatMessage> get history => List.unmodifiable(_history);

  /// Appends a system message to the session conversation history.
  void addSystemMessage(String content) {
    _history.add(ChatMessage.system(content));
  }

  @override
  Stream<A2uiMessage> get incomingMessages => _adapter.incomingMessages;

  @override
  Stream<String> get incomingText => _textStreamController.stream;

  /// Maps standard A2UI [ChatMessage] objects to Genkit-compatible
  /// [genkit.Message] structures.
  genkit.Message _mapToGenkitMessage(ChatMessage msg) {
    final genkit.Role role = switch (msg.role) {
      ChatMessageRole.system => genkit.Role.system,
      ChatMessageRole.user => genkit.Role.user,
      ChatMessageRole.model => genkit.Role.model,
    };

    final List<genkit.Part> parts = [];
    for (final StandardPart part in msg.parts) {
      if (part.isUiInteractionPart) {
        parts.add(genkit.TextPart(text: part.asUiInteractionPart!.interaction));
      } else if (part is TextPart) {
        parts.add(genkit.TextPart(text: part.text));
      }
    }

    return genkit.Message(role: role, content: parts);
  }

  @override
  Future<void> sendRequest(ChatMessage message) async {
    // Reset stream interception states
    _insideA2ui = false;
    _insideJson = false;
    _dslLines.clear();
    _jsonLines.clear();
    _lineBuffer.clear();

    // Add user message to internal history list
    _history.add(message);

    // Construct Genkit history messages list representing
    // the entire conversation.
    // We dynamically doctor the final user prompt to append strict
    // on-device layout guidelines and positional argument constraints,
    // keeping user-visible history clean while guaranteeing that
    // Gemini Nano focuses on compact DSL.
    final List<genkit.Message> genkitHistory = [];
    for (var i = 0; i < _history.length; i++) {
      final ChatMessage msg = _history[i];
      if (i == _history.length - 1 && msg.role == ChatMessageRole.user) {
        final doctoredMsg = ChatMessage(
          role: ChatMessageRole.user,
          parts: [
            ...msg.parts,
            const TextPart(
              '\n\n'
              'IMPORTANT: You MUST output the user interface using the compact '
              'A2UI Express DSL notation. '
              'You MUST surround the entire A2UI Express DSL block with the '
              'sentinel tags `<a2ui>` and `</a2ui>` '
              'to separate it from your conversational explanation.\n\n'
              'CRITICAL: In your generated A2UI Express DSL code, you MUST '
              'ONLY pass positional arguments inside all component '
              'constructors (e.g. Component(arg1, arg2)). '
              'Do NOT use named arguments, property keys, or key-value '
              'assignments inside any component constructor (e.g. never '
              'write Component(key = value) or Component(key: value)!).',
            ),
          ],
        );
        genkitHistory.add(_mapToGenkitMessage(doctoredMsg));
      } else {
        genkitHistory.add(_mapToGenkitMessage(msg));
      }
    }

    // Invoke Genkit generation stream using the complete history messages list
    final Stream<genkit.GenerateResponseChunk<Object?>> stream = ai
        .generateStream<Object?, Object?>(
          model: model,
          messages: genkitHistory,
        );

    final fullResponseBuffer = StringBuffer();

    await for (final chunk in stream) {
      final String chunkText = chunk.text;
      if (chunkText.isEmpty) continue;

      fullResponseBuffer.write(chunkText);

      // Buffers chunks and splits them by lines to isolate sentinel tags
      _lineBuffer.write(chunkText);
      final currentText = _lineBuffer.toString();
      final List<String> lines = currentText.split('\n');

      if (lines.length > 1) {
        final String incompleteLine = lines.last;
        _lineBuffer.clear();
        _lineBuffer.write(incompleteLine);

        for (var i = 0; i < lines.length - 1; i++) {
          final String line = lines[i];
          final String trimmed = line.trim();

          // ignore: avoid_print
          print('[ExpressLocalTransport] Streamed line: "$line"');

          if (trimmed.contains('<a2ui>')) {
            _insideA2ui = true;
            continue;
          }
          if (trimmed.contains('</a2ui>')) {
            _insideA2ui = false;
            continue;
          }
          if (trimmed.contains('```json')) {
            _insideJson = true;
            continue;
          }
          if (trimmed.contains('```') && _insideJson) {
            _insideJson = false;
            continue;
          }

          if (_insideA2ui) {
            _dslLines.add(line);
          } else if (_insideJson) {
            _jsonLines.add(line);
          } else {
            if (!trimmed.startsWith('```')) {
              _textStreamController.add('$line\n');
            }
          }
        }
      }
    }

    // Extract remaining line chunk on stream closure
    final remaining = _lineBuffer.toString();
    _lineBuffer.clear();
    final String trimmedRemaining = remaining.trim();
    if (remaining.isNotEmpty) {
      // ignore: avoid_print
      print('[ExpressLocalTransport] Remaining line: "$remaining"');

      if (trimmedRemaining.contains('<a2ui>')) {
        _insideA2ui = true;
      } else if (trimmedRemaining.contains('</a2ui>')) {
        _insideA2ui = false;
      } else if (trimmedRemaining.contains('```json')) {
        _insideJson = true;
      } else if (trimmedRemaining.contains('```') && _insideJson) {
        _insideJson = false;
      } else {
        if (_insideA2ui) {
          _dslLines.add(remaining);
        } else if (_insideJson) {
          _jsonLines.add(remaining);
        } else {
          if (!trimmedRemaining.startsWith('```')) {
            _textStreamController.add(remaining);
          }
        }
      }
    }

    // Append final full model response to the conversation history
    final responseText = fullResponseBuffer.toString();
    _history.add(ChatMessage.model(responseText));

    // 1. Compile DSL scripts if accumulated
    if (_dslLines.isNotEmpty) {
      final String dslText = _dslLines.join('\n').trim();
      if (dslText.isNotEmpty) {
        try {
          final surfaceId = 'surface_${DateTime.now().millisecondsSinceEpoch}';
          final Map<String, Object?> compiledMap = compiler.compile(
            dslText,
            surfaceId: surfaceId,
          );

          final createSurface =
              compiledMap['createSurface'] as Map<String, Object?>;
          final componentsList =
              createSurface.remove('components') as List<Object?>?;
          final dataModelMap =
              createSurface.remove('dataModel') as Map<String, Object?>?;

          // Emit CreateSurface
          final createMsg = A2uiMessage.fromJson(compiledMap);
          _adapter.addMessage(createMsg);

          // Emit UpdateComponents if present
          if (componentsList != null && componentsList.isNotEmpty) {
            final updateMap = <String, Object?>{
              'version': 'v0.9',
              'updateComponents': <String, Object?>{
                'surfaceId': surfaceId,
                'components': componentsList,
              },
            };
            final updateMsg = A2uiMessage.fromJson(updateMap);
            _adapter.addMessage(updateMsg);
          }

          // Emit UpdateDataModel if present
          if (dataModelMap != null && dataModelMap.isNotEmpty) {
            final dataMap = <String, Object?>{
              'version': 'v0.9',
              'updateDataModel': <String, Object?>{
                'surfaceId': surfaceId,
                'path': '/',
                'value': dataModelMap,
              },
            };
            final dataMsg = A2uiMessage.fromJson(dataMap);
            _adapter.addMessage(dataMsg);
          }
        } catch (e) {
          _textStreamController.add(
            '\n*(Failed to compile A2UI Express response: $e)*\n',
          );
        }
      }
    }

    // 2. Parse standard JSON envelopes if accumulated (liberal support for
    // both Maps and Lists)
    if (_jsonLines.isNotEmpty) {
      final String jsonText = _jsonLines.join('\n').trim();
      if (jsonText.isNotEmpty) {
        try {
          final Object? parsed = jsonDecode(jsonText);
          if (parsed is List) {
            for (final Object? item in parsed) {
              if (item is Map<String, Object?>) {
                final a2uiMsg = A2uiMessage.fromJson(item);
                _adapter.addMessage(a2uiMsg);
              }
            }
          } else if (parsed is Map<String, Object?>) {
            final a2uiMsg = A2uiMessage.fromJson(parsed);
            _adapter.addMessage(a2uiMsg);
          }
        } catch (e) {
          _textStreamController.add(
            '\n*(Failed to parse standard JSON response: $e)*\n',
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _adapter.dispose();
    _textStreamController.close();
  }
}
