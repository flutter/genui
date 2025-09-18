// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import '../models/component.dart';
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
  Map<String, Object?> _dataModel = {};
  String? _rootComponentId;
  bool _isReadyToRender = false;

  String? _error;

  /// Whether the interpreter has received enough information to render the UI.
  bool get isReadyToRender => _isReadyToRender;

  /// The ID of the root component in the UI.
  String? get rootComponentId => _rootComponentId;

  /// An error message, if any error has occurred.
  String? get error => _error;

  /// Processes a single JSONL message from the stream.
  void processMessage(String jsonl) {
    if (jsonl.isEmpty) {
      return;
    }
    try {
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
    } on UnknownComponentException catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('Error: $e');
    }
  }

  void _updateDataModel(String? path, dynamic contents) {
    if (path == null || path.isEmpty) {
      if (contents is Map<String, Object?>) {
        _dataModel = contents;
      } else if (contents is Map) {
        _dataModel = contents.cast<String, Object?>();
      } else {
        _error = 'Data model root must be a JSON object.';
      }
      return;
    }

    final segments = path
        .split(RegExp(r'\.|\[|\]'))
        .where((s) => s.isNotEmpty)
        .toList();
    if (segments.isEmpty) return;

    Object? current = _dataModel;

    for (var i = 0; i < segments.length - 1; i++) {
      final segment = segments[i];
      final nextSegment = segments[i + 1];
      final nextIsIndex = int.tryParse(nextSegment) != null;

      final index = int.tryParse(segment);
      if (index != null && current is List) {
        // Current segment is an index, and we are traversing a list.
        while (current.length <= index) {
          current.add(null);
        }
        if (current[index] == null ||
            (nextIsIndex && current[index] is! List) ||
            (!nextIsIndex && current[index] is! Map)) {
          current[index] = nextIsIndex ? <Object?>[] : <String, Object?>{};
        }
        current = current[index];
      } else if (current is Map<String, Object?>) {
        // Current segment is a key, and we are traversing a map.
        final key = segment;
        if (!current.containsKey(key) ||
            (nextIsIndex && current[key] is! List) ||
            (!nextIsIndex && current[key] is! Map)) {
          current[key] = nextIsIndex ? <Object?>[] : <String, Object?>{};
        }
        current = current[key];
      } else {
        // Path is invalid for the current data model structure.
        return;
      }
    }

    final lastSegment = segments.last;
    final lastIndex = int.tryParse(lastSegment);

    if (lastIndex != null && current is List) {
      final index = lastIndex;
      while (current.length <= index) {
        current.add(null);
      }
      current[index] = contents;
    } else if (current is Map<String, Object?>) {
      current[lastSegment] = contents;
    }
  }

  /// Retrieves a component by its [id].
  Component? getComponent(String id) => _components[id];

  /// Resolves a data binding path to a value in the data model.
  Object? resolveDataBinding(String path) {
    if (path.isEmpty) {
      return null;
    }
    final segments = path
        .split(RegExp(r'\.|\[|\]'))
        .where((s) => s.isNotEmpty)
        .toList();
    dynamic currentValue = _dataModel;
    for (final segment in segments) {
      if (currentValue == null) {
        return null;
      }

      final index = int.tryParse(segment);
      if (index != null && currentValue is List) {
        if (index >= 0 && index < currentValue.length) {
          currentValue = currentValue[index];
        } else {
          return null; // Index out of bounds.
        }
      } else if (currentValue is Map<String, Object?> &&
          currentValue.containsKey(segment)) {
        currentValue = currentValue[segment];
      } else {
        return null; // Path segment doesn't match data structure.
      }
    }
    return currentValue;
  }
}
