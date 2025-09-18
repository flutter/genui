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
  final Map<String, DataModelNode> _dataModelNodes = {};
  String? _rootComponentId;
  String? _dataModelRootId;
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
        for (final node in message.nodes) {
          _dataModelNodes[node.id] = node;
        }
        notifyListeners();
        break;
      case UiRoot():
        _rootComponentId = message.root;
        _dataModelRootId = message.dataModelRoot;
        _isReadyToRender = true;
        notifyListeners();
        break;
    }
  }

  /// Retrieves a component by its [id].
  Component? getComponent(String id) => _components[id];

  /// Retrieves a data model node by its [id].
  DataModelNode? getDataNode(String id) => _dataModelNodes[id];

  /// Resolves a data binding path to a value in the data model.
  Object? resolveDataBinding(String path) {
    if (_dataModelRootId == null) {
      return null;
    }
    final pathSegments = path.split('/').where((s) => s.isNotEmpty).toList();
    var currentNode = _dataModelNodes[_dataModelRootId];
    for (final segment in pathSegments) {
      if (currentNode == null) {
        return null;
      }
      if (currentNode.children != null &&
          currentNode.children!.containsKey(segment)) {
        currentNode = _dataModelNodes[currentNode.children![segment]];
      } else {
        return null;
      }
    }

    if (currentNode?.items != null) {
      final resolvedItems = <Map<String, dynamic>>[];
      for (final itemId in currentNode!.items!) {
        final itemNode = _dataModelNodes[itemId];
        if (itemNode?.children != null) {
          final resolvedItem = <String, dynamic>{};
          itemNode!.children!.forEach((key, valueId) {
            resolvedItem[key] = _dataModelNodes[valueId]?.value;
          });
          resolvedItems.add(resolvedItem);
        }
      }
      return resolvedItems;
    }

    return currentNode?.value;
  }
}
