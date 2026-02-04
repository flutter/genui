// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../model/a2ui_message.dart';
import '../model/gen_ui_events.dart';
import '../model/ui_models.dart';
import 'a2ui_parser_transformer.dart';

export '../model/gen_ui_events.dart'
    show A2uiMessageEvent, GenUiEvent, TextEvent;

/// A state update for the UI.
typedef GenUiState = GenUiUpdate;

/// The primary high-level API for typical Flutter application development.
///
/// It wraps the [A2uiParserTransformer] to provide an imperative, push-based
/// interface that is easier to integrate into imperative loops.
class A2uiTransportAdapter {
  /// Creates a [A2uiTransportAdapter].
  A2uiTransportAdapter() {
    _pipeline = _inputStream.stream
        .transform(const A2uiParserTransformer())
        .asBroadcastStream();
  }

  final StreamController<String> _inputStream = StreamController();
  final StreamController<A2uiMessage> _messageStream =
      StreamController.broadcast();
  late final Stream<GenUiEvent> _pipeline;
  StreamSubscription<GenUiEvent>? _pipelineSubscription;

  /// Feeds a chunk of text from the LLM to the controller.
  ///
  /// The controller buffers and parses this internally using the transformer.
  void addChunk(String text) {
    _pipelineSubscription ??= _pipeline.listen((event) {
      if (event is A2uiMessageEvent) {
        _messageStream.add(event.message);
      }
    });
    _inputStream.add(text);
  }

  /// Feeds a raw A2UI message (e.g. from a tool output or separate channel).
  void addMessage(A2uiMessage message) {
    _messageStream.add(message);
  }

  /// A stream of sanitizer text for the chat UI.
  Stream<String> get textStream => _pipeline
      .where((e) => e is TextEvent)
      .cast<TextEvent>()
      .map((e) => e.text);

  /// A stream of A2UI messages parsed from the input.
  Stream<A2uiMessage> get messageStream => _messageStream.stream;

  /// Closes the controller and cleans up resources.
  void dispose() {
    _inputStream.close();
    _messageStream.close();
    _pipelineSubscription?.cancel();
  }
}
