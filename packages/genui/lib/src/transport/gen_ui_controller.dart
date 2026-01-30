// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/a2ui_message_processor.dart';
import '../model/a2ui_message.dart';
import '../model/catalog.dart';
import '../model/chat_message.dart';
import '../model/data_model.dart';
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
class GenUiController implements GenUiHost {
  /// Creates a [GenUiController].
  GenUiController({
    Iterable<Catalog>? catalogs,
    A2uiMessageProcessor? messageProcessor,
  }) : assert(
         catalogs != null || messageProcessor != null,
         'Either catalogs or messageProcessor must be provided',
       ),
       _processor =
           messageProcessor ?? A2uiMessageProcessor(catalogs: catalogs!) {
    // The controller builds the pipeline using the transformer
    _pipeline = _inputStream.stream
        .transform(const A2uiParserTransformer())
        .asBroadcastStream();

    _pipelineSubscription = _pipeline.listen((event) {
      if (event is A2uiMessageEvent) {
        _processor.handleMessage(event.message);
      }
    });
  }

  final A2uiMessageProcessor _processor;
  final StreamController<String> _inputStream = StreamController();
  late final Stream<GenUiEvent> _pipeline;
  late final StreamSubscription<GenUiEvent> _pipelineSubscription;

  /// Feeds a chunk of text from the LLM to the controller.
  ///
  /// The controller buffers and parses this internally using the transformer.
  void addChunk(String text) => _inputStream.add(text);

  /// Feeds a raw A2UI message (e.g. from a tool output or separate channel).
  void addMessage(A2uiMessage message) {
    _processor.handleMessage(message);
  }

  /// The internal processor managing the UI state.
  A2uiMessageProcessor get processor => _processor;

  /// A stream of sanitized text for the chat UI.
  Stream<String> get textStream => _pipeline
      .where((e) => e is TextEvent)
      .cast<TextEvent>()
      .map((e) => e.text);

  /// The stream used by the GenUiView widget to render.
  Stream<GenUiState> get stateStream => _processor.surfaceUpdates;

  /// User interactions that the developer needs to handle (e.g. sending to
  /// LLM).
  Stream<ChatMessage> get onClientEvent => _processor.onSubmit;

  /// Closes the controller and cleans up resources.
  void dispose() {
    _inputStream.close();
    _pipelineSubscription.cancel();
    _processor.dispose();
  }

  // GenUiHost implementation

  @override
  Stream<GenUiUpdate> get surfaceUpdates => _processor.surfaceUpdates;

  @override
  ValueNotifier<UiDefinition?> getSurfaceNotifier(String surfaceId) =>
      _processor.getSurfaceNotifier(surfaceId);

  @override
  Iterable<Catalog> get catalogs => _processor.catalogs;

  @override
  Map<String, DataModel> get dataModels => _processor.dataModels;

  @override
  DataModel dataModelForSurface(String surfaceId) =>
      _processor.dataModelForSurface(surfaceId);

  @override
  void handleUiEvent(UiEvent event) => _processor.handleUiEvent(event);
}
