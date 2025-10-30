// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import '../primitives/logging.dart';
import '../primitives/simple_items.dart';

@immutable
class DataPath {
  factory DataPath(String path) {
    return DataPath._(_split(path), path.startsWith(_separator));
  }

  const DataPath._(this.segments, this.isAbsolute);

  final List<String> segments;
  final bool isAbsolute;

  static final String _separator = '/';
  static const DataPath root = DataPath._([], true);

  static List<String> _split(String path) {
    if (path.startsWith(_separator)) {
      path = path.substring(1);
    }
    if (path.isEmpty) {
      return [];
    }
    return path.split(_separator);
  }

  String get basename => segments.last;

  DataPath get dirname =>
      DataPath._(segments.sublist(0, segments.length - 1), isAbsolute);

  DataPath join(DataPath other) {
    if (other.isAbsolute) {
      return other;
    }
    return DataPath._([...segments, ...other.segments], isAbsolute);
  }

  bool startsWith(DataPath other) {
    if (other.segments.length > segments.length) {
      return false;
    }
    for (var i = 0; i < other.segments.length; i++) {
      if (segments[i] != other.segments[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  String toString() {
    final path = segments.join(_separator);
    return isAbsolute ? '$_separator$path' : path;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataPath &&
          runtimeType == other.runtimeType &&
          isAbsolute == other.isAbsolute &&
          listEquals(segments, other.segments);

  @override
  int get hashCode => Object.hash(isAbsolute, Object.hashAll(segments));
}

/// A contextual view of the main DataModel, used by widgets to resolve
/// relative and absolute paths.
class DataContext {
  DataContext(this._dataModel, String path) : path = DataPath(path);

  DataContext._(this._dataModel, this.path);

  final DataModel _dataModel;
  final DataPath path;

  /// Subscribes to a path, resolving it against the current context.
  ValueNotifier<T?> subscribe<T>(DataPath relativeOrAbsolutePath) {
    final absolutePath = resolvePath(relativeOrAbsolutePath);
    return _dataModel.subscribe<T>(absolutePath);
  }

  /// Gets a static value, resolving the path against the current context.
  T? getValue<T>(DataPath relativeOrAbsolutePath) {
    final absolutePath = resolvePath(relativeOrAbsolutePath);
    return _dataModel.getValue<T>(absolutePath);
  }

  /// Updates the data model, resolving the path against the current context.
  void update(DataPath relativeOrAbsolutePath, Object? contents) {
    final absolutePath = resolvePath(relativeOrAbsolutePath);
    _dataModel.update(absolutePath, contents);
  }

  /// Creates a new, nested DataContext for a child widget.
  /// Used by list/template widgets for their children.
  DataContext nested(DataPath relativePath) {
    final newPath = resolvePath(relativePath);
    return DataContext._(_dataModel, newPath);
  }

  DataPath resolvePath(DataPath pathToResolve) {
    if (pathToResolve.isAbsolute) {
      return pathToResolve;
    }
    return path.join(pathToResolve);
  }
}

/// Manages the application's Object? data model and provides
/// a subscription-based mechanism for reactive UI updates.
class DataModel {
  JsonMap _data = {};
  final Map<DataPath, ValueNotifier<Object?>> _subscriptions = {};
  final Map<DataPath, ValueNotifier<Object?>> _valueSubscriptions = {};

  /// The full contents of the data model.
  JsonMap get data => _data;

  /// Updates the data model at a specific absolute path and notifies all
  /// relevant subscribers.
  void update(DataPath? absolutePath, Object? contents) {
    genUiLogger.info(
      'DataModel.update: path=$absolutePath, contents=$contents',
    );
    if (absolutePath == null || absolutePath.segments.isEmpty) {
      _data = contents as JsonMap;
      _notifySubscribers(DataPath('/'));
      return;
    }

    _updateValue(_data, absolutePath.segments, contents);
    _notifySubscribers(absolutePath);
  }

  /// Subscribes to a specific absolute path in the data model.
  ValueNotifier<T?> subscribe<T>(DataPath absolutePath) {
    genUiLogger.info('DataModel.subscribe: path=$absolutePath');
    final initialValue = getValue<T>(absolutePath);
    if (_subscriptions.containsKey(absolutePath)) {
      final notifier = _subscriptions[absolutePath]! as ValueNotifier<T?>;
      notifier.value = initialValue;
      return notifier;
    }
    final notifier = ValueNotifier<T?>(initialValue);
    _subscriptions[absolutePath] = notifier;
    return notifier;
  }

  /// Subscribes to a specific absolute path in the data model, only notifying
  /// when the value at that exact path changes.
  ValueNotifier<T?> subscribeToValue<T>(DataPath absolutePath) {
    genUiLogger.info('DataModel.subscribeToValue: path=$absolutePath');
    final initialValue = getValue<T>(absolutePath);
    if (_valueSubscriptions.containsKey(absolutePath)) {
      final notifier = _valueSubscriptions[absolutePath]! as ValueNotifier<T?>;
      notifier.value = initialValue;
      return notifier;
    }
    final notifier = ValueNotifier<T?>(initialValue);
    _valueSubscriptions[absolutePath] = notifier;
    return notifier;
  }

  /// Retrieves a static, one-time value from the data model at the
  /// specified absolute path without creating a subscription.
  T? getValue<T>(DataPath absolutePath) {
    return _getValue(_data, absolutePath.segments) as T?;
  }

  Object? _getValue(Object? current, List<String> segments) {
    if (segments.isEmpty) {
      return current;
    }

    final segment = segments.first;
    final remaining = segments.sublist(1);

    if (current is Map) {
      return _getValue(current[segment], remaining);
    } else if (current is List && segment.startsWith('[')) {
      final index = int.tryParse(segment.substring(1, segment.length - 1));
      if (index != null && index >= 0 && index < current.length) {
        return _getValue(current[index], remaining);
      }
    }
    return null;
  }

  void _updateValue(Object? current, List<String> segments, Object? value) {
    if (segments.isEmpty) {
      return;
    }

    final segment = segments.first;
    final remaining = segments.sublist(1);

    if (segment.startsWith('[')) {
      final index = int.tryParse(segment.substring(1, segment.length - 1));
      if (index != null && current is List && index >= 0) {
        if (remaining.isEmpty) {
          if (index < current.length) {
            current[index] = value;
          } else if (index == current.length) {
            current.add(value);
          } else {
            throw ArgumentError(
              'Index out of bounds for list update: index ($index) is greater '
              'than list length (${current.length}).',
            );
          }
        } else {
          if (index < current.length) {
            _updateValue(current[index], remaining, value);
          } else {
            throw ArgumentError(
              'Index out of bounds for nested update: index ($index) is '
              'greater than or equal to list length (${current.length}).',
            );
          }
        }
      }
    } else {
      if (current is Map) {
        if (remaining.isEmpty) {
          current[segment] = value;
        } else {
          if (!current.containsKey(segment)) {
            if (remaining.first.startsWith('[')) {
              current[segment] = <Object?>[];
            } else {
              current[segment] = <String, Object?>{};
            }
          }
          _updateValue(current[segment], remaining, value);
        }
      }
    }
  }

  void _notifySubscribers(DataPath path) {
    genUiLogger.info('DataModel._notifySubscribers: notifying for path=$path');
    for (final p in _subscriptions.keys) {
      if (p.startsWith(path) || path.startsWith(p)) {
        genUiLogger.info('  - Notifying subscriber for path=$p');
        final subscriber = _subscriptions[p];
        if (subscriber != null) {
          subscriber.value = getValue<Object?>(p);
        }
      }
    }
    if (_valueSubscriptions.containsKey(path)) {
      genUiLogger.info('  - Notifying value subscriber for path=$path');
      final subscriber = _valueSubscriptions[path];
      if (subscriber != null) {
        subscriber.value = getValue<Object?>(path);
      }
    }
  }
}
