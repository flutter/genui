// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:genui/genui.dart';

import 'agent/agent.dart';
import 'agent/ai_client.dart';
import 'express/compiler.dart';

class ExtractionResult {
  final String explanationText;
  final String expressDsl;
  ExtractionResult(this.explanationText, this.expressDsl);
}

ExtractionResult extractExpressAndText(String fullText) {
  final List<String> explanationLines = [];
  final List<String> dslLines = [];

  final List<String> lines = fullText.split('\n');
  var insideA2ui = false;

  for (final line in lines) {
    final String trimmed = line.trim();
    if (trimmed.contains('<a2ui>')) {
      insideA2ui = true;
      continue;
    }
    if (trimmed.contains('</a2ui>')) {
      insideA2ui = false;
      continue;
    }

    if (insideA2ui) {
      dslLines.add(line);
    } else {
      if (!trimmed.startsWith('```')) {
        explanationLines.add(line);
      }
    }
  }

  return ExtractionResult(
    explanationLines.join('\n').trim(),
    dslLines.join('\n').trim(),
  );
}

/// A [Transport] that communicates with [SimpleChatAgent] using A2UI Express.
class ExpressChatA2aTransport implements Transport {
  final Catalog catalog;
  late final SimpleChatAgent _agent;
  final A2uiTransportAdapter _adapter = A2uiTransportAdapter();
  final ExpressCompiler _compiler;

  final StringBuffer _lineBuffer = StringBuffer();
  bool _insideA2ui = false;

  final StreamController<String> _textStreamController =
      StreamController<String>.broadcast();

  ExpressChatA2aTransport({AiClient? aiClient, required this.catalog})
    : _compiler = ExpressCompiler(catalog) {
    _agent = SimpleChatAgent(
      aiClient: aiClient,
      onChunkFromAgent: (chunk) {
        _lineBuffer.write(chunk);
        final currentText = _lineBuffer.toString();
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

            if (!_insideA2ui && !trimmed.startsWith('```')) {
              _textStreamController.add('$line\n');
            }
          }
        }
      },
    );
  }

  @override
  Stream<A2uiMessage> get incomingMessages => _adapter.incomingMessages;

  @override
  Stream<String> get incomingText => _textStreamController.stream;

  @override
  Future<void> sendRequest(ChatMessage message) async {
    final buffer = StringBuffer();
    _insideA2ui = false;

    // Intercept the agent's response to parse it at completion
    final interceptAgent = SimpleChatAgent(
      aiClient: _agent.aiClient,
      onChunkFromAgent: (chunk) {
        buffer.write(chunk);
        _lineBuffer.write(chunk);
        final currentText = _lineBuffer.toString();
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

            if (!_insideA2ui && !trimmed.startsWith('```')) {
              _textStreamController.add('$line\n');
            }
          }
        }
      },
    );
    // Sync the history with standard agent; Just to match lists, but let's
    // copy history instead
    interceptAgent.addSystemMessage('');

    // We temporarily replace/simulate the agent run to gather full text
    await _agent.handleRequestFromRenderer(message);

    // Flush any remaining text in the buffer on stream completion
    final remaining = _lineBuffer.toString();
    _lineBuffer.clear();
    final String trimmedRemaining = remaining.trim();
    if (remaining.isNotEmpty &&
        !trimmedRemaining.contains('<a2ui>') &&
        !trimmedRemaining.contains('</a2ui>') &&
        !_insideA2ui &&
        !trimmedRemaining.startsWith('```')) {
      _textStreamController.add(remaining);
    }

    // Standard agent completes and updates its history.
    // Let's find the last model response from the agent's history
    final String lastModelResponse = _agent.history.last.text;

    final ExtractionResult result = extractExpressAndText(lastModelResponse);

    if (result.expressDsl.isNotEmpty) {
      try {
        final surfaceId = 'surface_${DateTime.now().millisecondsSinceEpoch}';
        final Map<String, dynamic> compiledMap = _compiler.compile(
          result.expressDsl,
          surfaceId: surfaceId,
        );

        final createSurface =
            compiledMap['createSurface'] as Map<String, dynamic>;
        final componentsList =
            createSurface.remove('components') as List<dynamic>?;

        // 1. Emit CreateSurface message
        final createMsg = A2uiMessage.fromJson(compiledMap);
        _adapter.addMessage(createMsg);

        // 2. Emit UpdateComponents message
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
      } catch (e) {
        // Gracefully fallback if express compilation fails
        _textStreamController.add('\n*(Failed to compile UI response: $e)*\n');
      }
    }
  }

  @override
  void dispose() {
    _adapter.dispose();
    _textStreamController.close();
  }

  /// Adds a system message to the history.
  void addSystemMessage(String content) => _agent.addSystemMessage(content);
}
