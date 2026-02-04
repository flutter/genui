// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../interfaces/gen_ui_transport.dart';
import '../model/a2ui_message.dart';
import '../model/chat_message.dart';
import '../model/gen_ui_events.dart';
import '../model/ui_models.dart';
import 'a2ui_parser_transformer.dart';

export '../model/gen_ui_events.dart'
    show A2uiMessageEvent, GenUiEvent, TextEvent;

/// A state update for the UI.
typedef GenUiState = GenUiUpdate;

/// A manual sender callback.
typedef ManualSendCallback = Future<void> Function(ChatMessage message);

/// The primary high-level API for typical Flutter application development.
///
/// It wraps the [A2uiParserTransformer] to provide an imperative, push-based
/// interface that is easier to integrate into imperative loops.
///
/// Use [addChunk] to feed text chunks from an LLM.
/// Use [addMessage] to feed raw A2UI messages.
class A2uiTransportAdapter implements GenUiTransport {
  /// Creates a [A2uiTransportAdapter].
  ///
  /// The [onSend] callback is required if [sendRequest] will be called.
  A2uiTransportAdapter({this.onSend}) {
    _pipeline = _inputStream.stream
        .transform(const A2uiParserTransformer())
        .asBroadcastStream();
  }

  /// The callback to invoke when [sendRequest] is called.
  final ManualSendCallback? onSend;

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
  @override
  Stream<String> get incomingText => _pipeline
      .where((e) => e is TextEvent)
      .cast<TextEvent>()
      .map((e) => e.text);

  // Legacy alias
  Stream<String> get textStream => incomingText;

  /// A stream of A2UI messages parsed from the input.
  @override
  Stream<A2uiMessage> get incomingMessages => _messageStream.stream;

  // Legacy alias
  Stream<A2uiMessage> get messageStream => incomingMessages;

  @override
  Future<void> sendRequest(ChatMessage message) async {
    if (onSend == null) {
      throw StateError(
        'A2uiTransportAdapter.onSend must be provided to use sendRequest.',
      );
    }
    await onSend!(message);
  }

  /// Closes the controller and cleans up resources.
  @override
  void dispose() {
    _inputStream.close();
    _messageStream.close();
    _pipelineSubscription?.cancel();
  }
}
