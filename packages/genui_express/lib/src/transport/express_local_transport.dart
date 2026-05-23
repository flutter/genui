// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:genkit/genkit.dart' hide TextPart;
import 'package:genui/genui.dart';

import '../compiler/express_compiler.dart';

/// A [Transport] implementation that coordinates local Genkit LLM inference
/// streams and compiles their Express layout DSL outputs into A2UI messages.
class ExpressLocalTransport implements Transport {
  /// The core Genkit engine instance.
  final Genkit ai;

  /// The target Genkit model reference.
  final ModelRef model;

  /// The A2UI Express compiler instance.
  final ExpressCompiler compiler;

  /// The component catalog used for property mapping constraints.
  final Catalog catalog;

  final A2uiTransportAdapter _adapter = A2uiTransportAdapter();
  final StreamController<String> _textStreamController =
      StreamController<String>.broadcast();

  final StringBuffer _lineBuffer = StringBuffer();
  final List<String> _dslLines = [];
  bool _insideA2ui = false;

  ExpressLocalTransport({
    required this.ai,
    required this.model,
    required this.catalog,
  }) : compiler = ExpressCompiler(catalog);

  @override
  Stream<A2uiMessage> get incomingMessages => _adapter.incomingMessages;

  @override
  Stream<String> get incomingText => _textStreamController.stream;

  @override
  Future<void> sendRequest(ChatMessage message) async {
    // Reset stream interception states
    _insideA2ui = false;
    _dslLines.clear();
    _lineBuffer.clear();

    // Extract prompt text from ChatMessage parts
    final buffer = StringBuffer();
    for (final part in message.parts) {
      if (part.isUiInteractionPart) {
        buffer.write(part.asUiInteractionPart!.interaction);
      } else if (part is TextPart) {
        buffer.write(part.text);
      }
    }

    final String promptText = buffer.toString();
    if (promptText.isEmpty) return;

    // Invoke Genkit generation stream
    final stream = ai.generateStream(model: model, prompt: promptText);

    await for (final chunk in stream) {
      final String chunkText = chunk.text;
      if (chunkText.isEmpty) continue;

      // Buffers chunks and splits them by lines to isolate sentinel tags
      _lineBuffer.write(chunkText);
      final String currentText = _lineBuffer.toString();
      final List<String> lines = currentText.split('\n');

      if (lines.length > 1) {
        final String incompleteLine = lines.last;
        _lineBuffer.clear();
        _lineBuffer.write(incompleteLine);

        for (var i = 0; i < lines.length - 1; i++) {
          final String line = lines[i];
          final String trimmed = line.trim();
          if (trimmed.contains('<a2ui>')) {
            _insideA2ui = true;
            continue;
          }
          if (trimmed.contains('</a2ui>')) {
            _insideA2ui = false;
            continue;
          }

          if (_insideA2ui) {
            _dslLines.add(line);
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
      if (trimmedRemaining.contains('<a2ui>')) {
        _insideA2ui = true;
      } else if (trimmedRemaining.contains('</a2ui>')) {
        _insideA2ui = false;
      } else {
        if (_insideA2ui) {
          _dslLines.add(remaining);
        } else {
          if (!trimmedRemaining.startsWith('```')) {
            _textStreamController.add(remaining);
          }
        }
      }
    }

    // Compile DSL scripts if accumulated
    if (_dslLines.isNotEmpty) {
      final String dslText = _dslLines.join('\n').trim();
      if (dslText.isNotEmpty) {
        try {
          final String surfaceId =
              'surface_${DateTime.now().millisecondsSinceEpoch}';
          final Map<String, dynamic> compiledMap = compiler.compile(
            dslText,
            surfaceId: surfaceId,
          );

          final createSurface =
              compiledMap['createSurface'] as Map<String, dynamic>;
          final componentsList =
              createSurface.remove('components') as List<dynamic>?;
          final dataModelMap =
              createSurface.remove('dataModel') as Map<String, dynamic>?;

          // 1. Emit CreateSurface
          final createMsg = A2uiMessage.fromJson(compiledMap);
          _adapter.addMessage(createMsg);

          // 2. Emit UpdateComponents if present
          if (componentsList != null && componentsList.isNotEmpty) {
            final updateMap = <String, dynamic>{
              'version': 'v0.9',
              'updateComponents': <String, dynamic>{
                'surfaceId': surfaceId,
                'components': componentsList,
              },
            };
            final updateMsg = A2uiMessage.fromJson(updateMap);
            _adapter.addMessage(updateMsg);
          }

          // 3. Emit UpdateDataModel if present
          if (dataModelMap != null && dataModelMap.isNotEmpty) {
            final dataMap = <String, dynamic>{
              'version': 'v0.9',
              'updateDataModel': <String, dynamic>{
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
  }

  @override
  void dispose() {
    _adapter.dispose();
    _textStreamController.close();
  }
}
