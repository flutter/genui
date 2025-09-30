// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import '../primitives/simple_items.dart';

/// A contextual view of the main DataModel, used by widgets to resolve
/// relative and absolute paths.
class DataContext {
  final DataModel _dataModel;
  final String basePath; // e.g., "/", "/users/1"

  DataContext(this._dataModel, this.basePath);

  /// Subscribes to a path, resolving it against the current context.
  ValueNotifier<T?> subscribe<T>(String relativeOrAbsolutePath) {
    final absolutePath = resolvePath(relativeOrAbsolutePath);
    return _dataModel.subscribe<T>(absolutePath);
  }

  /// Gets a static value, resolving the path against the current context.
  T? getValue<T>(String relativeOrAbsolutePath) {
    final absolutePath = resolvePath(relativeOrAbsolutePath);
    return _dataModel.getValue<T>(absolutePath);
  }

  /// Updates the data model, resolving the path against the current context.
  void update(String relativeOrAbsolutePath, dynamic contents) {
    final absolutePath = resolvePath(relativeOrAbsolutePath);
    _dataModel.update(absolutePath, contents);
  }

  /// Creates a new, nested DataContext for a child widget.
  /// Used by list/template widgets for their children.
  DataContext nested(String relativePath) {
    final newBasePath = resolvePath(relativePath);
    return DataContext(_dataModel, newBasePath);
  }

  String resolvePath(String path) {
    if (path.startsWith('/')) {
      return path; // It's an absolute path.
    }
    if (basePath == '/') {
      return '/$path';
    }
    // Join _basePath and path to create the new absolute path.
    // e.g., _basePath = "/users/1", path = "name" -> "/users/1/name"
    return '$basePath/$path';
  }
}

/// Manages the application's dynamic data model and provides
/// a subscription-based mechanism for reactive UI updates.
class DataModel {
  JsonMap _data = {};
  final Map<String, ValueNotifier<dynamic>> _subscriptions = {};

  /// Updates the data model at a specific absolute path and notifies all
  /// relevant subscribers.
  void update(String? absolutePath, dynamic contents) {
    if (absolutePath == null || absolutePath.isEmpty || absolutePath == '/') {
      _data = contents as JsonMap;
      _notifySubscribers('/');
      return;
    }

    final segments = _parsePath(absolutePath);
    _updateValue(_data, segments, contents);
    _notifySubscribers(absolutePath);
  }

  /// Subscribes to a specific absolute path in the data model.
  ValueNotifier<T?> subscribe<T>(String absolutePath) {
    if (_subscriptions.containsKey(absolutePath)) {
      return _subscriptions[absolutePath]! as ValueNotifier<T?>;
    }
    final initialValue = getValue<T>(absolutePath);
    final notifier = ValueNotifier<T?>(initialValue);
    _subscriptions[absolutePath] = notifier;
    return notifier;
  }

  /// Retrieves a static, one-time value from the data model at the
  /// specified absolute path without creating a subscription.
  T? getValue<T>(String absolutePath) {
    final segments = _parsePath(absolutePath);
    return _getValue(_data, segments) as T?;
  }

  List<String> _parsePath(String path) {
    if (path.startsWith('/')) {
      path = path.substring(1);
    }
    return path.split('/');
  }

  dynamic _getValue(dynamic current, List<String> segments) {
    if (segments.isEmpty || (segments.length == 1 && segments.first.isEmpty)) {
      return current;
    }

    final segment = segments.first;
    final remaining = segments.sublist(1);

    if (current is Map) {
      return _getValue(current[segment], remaining);
    } else if (current is List) {
      final index = int.tryParse(
        segment.replaceAll('[', '').replaceAll(']', ''),
      );
      if (index != null && index >= 0 && index < current.length) {
        return _getValue(current[index], remaining);
      }
    }
    return null;
  }

  void _updateValue(dynamic current, List<String> segments, dynamic value) {
    if (segments.length == 1) {
      final segment = segments.first;
      if (current is Map) {
        current[segment] = value;
      } else if (current is List) {
        final index = int.tryParse(
          segment.replaceAll('[', '').replaceAll(']', ''),
        );
        if (index != null && index >= 0 && index < current.length) {
          current[index] = value;
        }
      }
      return;
    }

    final segment = segments.first;
    final remaining = segments.sublist(1);

    if (current is Map) {
      if (!current.containsKey(segment)) {
        // Check if the next segment is a list index
        if (remaining.first.startsWith('[')) {
          current[segment] = <dynamic>[];
        } else {
          current[segment] = <String, dynamic>{};
        }
      }
      _updateValue(current[segment], remaining, value);
    } else if (current is List) {
      final index = int.tryParse(
        segment.replaceAll('[', '').replaceAll(']', ''),
      );
      if (index != null && index >= 0 && index < current.length) {
        _updateValue(current[index], remaining, value);
      }
    }
  }

  void _notifySubscribers(String path) {
    final affectedPaths = _getAffectedPaths(path);
    for (final p in affectedPaths) {
      final subscriber = _subscriptions[p];
      if (subscriber != null) {
        subscriber.value = getValue<dynamic>(p);
      }
    }
  }

  List<String> _getAffectedPaths(String? path) {
    if (path == null || path.isEmpty || path == '/') {
      return ['/'];
    }
    final segments = _parsePath(path);
    final paths = <String>['/'];
    var currentPath = '';
    for (final segment in segments) {
      if (segment.isEmpty) continue;
      currentPath += '/$segment';
      paths.add(currentPath);
    }
    return paths;
  }
}
