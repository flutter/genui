// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import '../models/component.dart';
import '../models/data_node.dart';
import '../models/stream_message.dart';

/// A client-side interpreter for the GULF Streaming UI Protocol.
///
/// This class processes a stream of JSONL messages from a server, manages the
/// UI state, and builds a renderable layout. It notifies listeners when the UI
/// should be updated.
class GulfInterpreter with ChangeNotifier {
  /// Creates an [GulfInterpreter] that processes the given [stream] of JSONL
  /// messages.
  GulfInterpreter({required this.stream}) {
    stream.listen(processMessage);
  }

  /// The input stream of raw JSONL strings from the server.
  final Stream<String> stream;

  final Map<String, Component> _components = {};
  Map<String, dynamic> _dataModel = {};
  String? _rootComponentId;
  bool _isReadyToRender = false;

  /// Whether the interpreter has received enough information to render the UI.
  bool get isReadyToRender => _isReadyToRender;

  /// The ID of the root component in the UI.
  String? get rootComponentId => _rootComponentId;

  /// Processes a single JSONL message from the stream.
  void processMessage(String jsonl) {
    if (jsonl.isEmpty) {
      return;
    }
    final json = jsonDecode(jsonl) as Map<String, Object?>;
    final message = GulfStreamMessage.fromJson(json);
    switch (message) {
      case StreamHeader():
        // Nothing to do for now.
        break;
      case ComponentUpdate():
        for (final component in message.components) {
          _components[component.id] = component;
        }
        break;
      case DataModelUpdate():
        _updateDataModel(message.path, message.contents);
        notifyListeners();
        break;
      case BeginRendering():
        _rootComponentId = message.root;
        _isReadyToRender = true;
        notifyListeners();
        break;
    }
  }

  void _updateDataModel(String? path, dynamic contents) {
    if (path == null || path.isEmpty) {
      _dataModel = contents as Map<String, dynamic>;
      return;
    }

    final segments = path.split('.');
    var currentLevel = _dataModel;

    for (var i = 0; i < segments.length - 1; i++) {
      final segment = segments[i];
      if (!currentLevel.containsKey(segment) || currentLevel[segment] is! Map) {
        currentLevel[segment] = <String, dynamic>{};
      }
      currentLevel = currentLevel[segment] as Map<String, dynamic>;
    }

    currentLevel[segments.last] = contents;
  }

  /// Retrieves a component by its [id].
  Component? getComponent(String id) => _components[id];

  /// Resolves a data binding path to a value in the data model.
  Object? resolveDataBinding(String path) {
    if (path.isEmpty) {
      return null;
    }
    final segments = path.split('.').where((s) => s.isNotEmpty).toList();
    dynamic currentValue = _dataModel;
    for (final segment in segments) {
      if (currentValue is Map<String, dynamic> &&
          currentValue.containsKey(segment)) {
        currentValue = currentValue[segment];
      } else if (currentValue is List) {
        final index = int.tryParse(segment);
        if (index != null && index >= 0 && index < currentValue.length) {
          currentValue = currentValue[index];
        } else {
          return null;
        }
      } else {
        return null;
      }
    }
    return currentValue;
  }
}
