// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../models/component.dart';
import '../models/stream_message.dart';

final _log = Logger('A2uiInterpreter');

class _SurfaceState {
  final Map<String, Component> components = {};
  Map<String, Object?> dataModel = {};
  String? rootComponentId;
  bool isReadyToRender = false;
}

/// A client-side interpreter for the A2UI Streaming UI Protocol.
///
/// This class processes a stream of JSONL messages from a server, manages the
/// UI state, and builds a renderable layout. It notifies listeners when the UI
/// should be updated.
class A2uiInterpreter with ChangeNotifier {
  /// Creates an [A2uiInterpreter] that processes the given [stream] of JSONL
  /// messages.
  A2uiInterpreter({required this.stream}) {
    _subscription = stream.listen(processMessage);
  }

  /// The input stream of raw JSONL strings from the server.
  final Stream<String> stream;
  StreamSubscription<String>? _subscription;

  final Map<String, _SurfaceState> _surfaces = {};
  String? _activeSurfaceId;

  String? _error;

  /// Whether the interpreter has received enough information to render the UI.
  bool get isReadyToRender =>
      _activeSurfaceId != null && _surfaces[_activeSurfaceId]!.isReadyToRender;

  /// The ID of the root component in the UI.
  String? get rootComponentId => _activeSurfaceId != null
      ? _surfaces[_activeSurfaceId]!.rootComponentId
      : null;

  /// An error message, if any error has occurred.
  String? get error => _error;

  /// Processes a single JSONL message from the stream.
  ///
  /// This method is called for each line in the input stream. It parses the
  /// JSON, determines the message type, and updates the interpreter's state
  /// accordingly.
  void processMessage(String jsonl) {
    if (jsonl.isEmpty) {
      return;
    }
    _log.fine('Processing JSONL message: $jsonl');
    try {
      final json = jsonDecode(jsonl) as Map<String, Object?>;
      final message = A2uiStreamMessage.fromJson(json);
      _log.finer('Parsed message: $message');

      // For this spike, we only handle one surface at a time.
      _activeSurfaceId ??= switch (message) {
        BeginRendering(surfaceId: final id) => id,
        SurfaceUpdate(surfaceId: final id) => id,
        DataModelUpdate(surfaceId: final id) => id,
        SurfaceDeletion(surfaceId: final id) => id,
      };

      final surfaceState = _surfaces.putIfAbsent(
        _activeSurfaceId!,
        _SurfaceState.new,
      );

      switch (message) {
        case SurfaceUpdate():
          _log.info(
            'Received SurfaceUpdate with ${message.components.length} '
            'components for surface ${message.surfaceId}.',
          );
          for (final component in message.components) {
            _log.finer('Updating component: ${component.id}');
            surfaceState.components[component.id] = component;
          }
          break;
        case DataModelUpdate():
          _log.info(
            'Received DataModelUpdate at path "${message.path}" for surface '
            '${message.surfaceId}.',
          );
          _updateDataModel(surfaceState, message.path, message.contents);
          notifyListeners();
          break;
        case BeginRendering():
          _log.info(
            'Received BeginRendering with root "${message.root}" for surface '
            '${message.surfaceId}.',
          );
          surfaceState.rootComponentId = message.root;
          surfaceState.isReadyToRender = true;
          notifyListeners();
          break;
        case SurfaceDeletion():
          _log.info(
            'Received SurfaceDeletion for surface ${message.surfaceId}.',
          );
          _surfaces.remove(message.surfaceId);
          if (_activeSurfaceId == message.surfaceId) {
            _activeSurfaceId = _surfaces.keys.firstOrNull;
          }
          notifyListeners();
          break;
      }
    } on UnknownComponentException catch (e, s) {
      _error = e.toString();
      _log.severe('Error processing message', e, s);
      notifyListeners();
    } catch (e, s) {
      _error = e.toString();
      _log.severe(
        'An unexpected error occurred while processing message',
        e,
        s,
      );
      notifyListeners();
    }
  }

  /// Updates the data model at the given [path] with the given [value].
  ///
  /// This method is used to update the data model from the client-side, for
  /// example when a user interacts with a form field.
  void updateData(String path, dynamic value) {
    if (_activeSurfaceId == null) return;
    _updateDataModel(_surfaces[_activeSurfaceId]!, path, value);
    notifyListeners();
  }

  void _updateDataModel(
    _SurfaceState surfaceState,
    String? path,
    dynamic contents,
  ) {
    _log.finer('Updating data model at path "$path" with contents: $contents');
    if (path == null || path.isEmpty || path == '/') {
      if (contents is Map<String, Object?>) {
        surfaceState.dataModel = contents;
        _log.finer('Replaced root data model.');
      } else if (contents is Map) {
        surfaceState.dataModel = contents.cast<String, Object?>();
        _log.finer('Replaced root data model (after casting).');
      } else {
        _error = 'Data model root must be a JSON object.';
        _log.severe(_error);
      }
      return;
    }

    final segments = path
        .split(RegExp(r'\/|\.|\[|\]'))
        .where((s) => s.isNotEmpty)
        .toList();
    if (segments.isEmpty) return;

    Object? current = surfaceState.dataModel;

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
  Component? getComponent(String id) => _activeSurfaceId != null
      ? _surfaces[_activeSurfaceId]!.components[id]
      : null;

  /// Resolves a data binding path to a value in the data model.
  Object? resolveDataBinding(String path) {
    if (_activeSurfaceId == null) return null;
    final surfaceState = _surfaces[_activeSurfaceId]!;
    _log.finer('Resolving data binding for path: "$path"');
    if (path.isEmpty) {
      _log.warning('Attempted to resolve empty data binding path.');
      return null;
    }
    final segments = path
        .split(RegExp(r'\/|\.|\[|\]'))
        .where((s) => s.isNotEmpty)
        .toList();
    dynamic currentValue = surfaceState.dataModel;
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
        _log.warning(
          'Data binding path segment "$segment" in "$path" does not match '
          'data structure.',
        );
        return null; // Path segment doesn't match data structure.
      }
    }
    _log.finer(
      'Resolved data binding for path "$path" to value: $currentValue',
    );
    return currentValue;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
