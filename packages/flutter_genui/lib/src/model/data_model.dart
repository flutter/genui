// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../primitives/logging.dart';
import '../primitives/simple_items.dart';

@immutable
class DataPath {
  factory DataPath(String path) {
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    return DataPath._(segments, path.startsWith(_separator));
  }

  const DataPath._(this.segments, this.isAbsolute);

  final List<String> segments;
  final bool isAbsolute;

  static final String _separator = '/';
  static const DataPath root = DataPath._([], true);

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
  void update(DataPath relativeOrAbsolutePath, dynamic contents) {
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

/// Manages the application's dynamic data model and provides
/// a subscription-based mechanism for reactive UI updates.
class DataModel {
  JsonMap _data = {};
  final Map<DataPath, ValueNotifier<dynamic>> _subscriptions = {};
  final Map<DataPath, ValueNotifier<dynamic>> _valueSubscriptions = {};

  /// The full contents of the data model.
  JsonMap get data => _data;

  /// Updates the data model at a specific absolute path and notifies all
  /// relevant subscribers.
  void update(DataPath? absolutePath, dynamic contents) {
    genUiLogger.info(
      'DataModel.update: path=$absolutePath, contents='
      '${const JsonEncoder.withIndent('  ').convert(contents)}',
    );
    if (absolutePath == null || absolutePath.segments.isEmpty) {
      if (contents is List) {
        _data = _parseDataModelContents(contents);
      } else if (contents is Map) {
        // Permissive: Allow a map to be sent for the root, even though the
        // schema expects a list.
        genUiLogger.info(
          'DataModel.update: contents for root path is a Map, not a '
          'List: $contents',
        );
        _data = Map<String, Object?>.from(contents);
      } else {
        genUiLogger.warning(
          'DataModel.update: contents for root path is not a List or '
          'Map: $contents',
        );
        _data = <String, Object?>{}; // Fallback
      }
      _notifySubscribers(DataPath.root);
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

  JsonMap _parseDataModelContents(List<Object?> contents) {
    final newData = <String, Object?>{};
    for (final item in contents) {
      if (item is Map<String, Object?> && item.containsKey('key')) {
        final key = item['key'] as String;
        Object? value;
        var valueCount = 0;

        const valueKeys = [
          'valueString',
          'valueNumber',
          'valueBoolean',
          'valueMap',
        ];
        for (final valueKey in valueKeys) {
          if (item.containsKey(valueKey)) {
            if (valueCount == 0) {
              if (valueKey == 'valueMap') {
                if (item[valueKey] is List) {
                  value = _parseDataModelContents(
                    (item[valueKey] as List).cast<Object?>(),
                  );
                } else {
                  genUiLogger.warning(
                    'valueMap for key "$key" is not a List: ${item[valueKey]}',
                  );
                }
              } else {
                value = item[valueKey];
              }
            }
            valueCount++;
          }
        }

        if (valueCount == 0) {
          genUiLogger.warning(
            'No value field found for key "$key" in contents: $item',
          );
        } else if (valueCount > 1) {
          genUiLogger.warning(
            'Multiple value fields found for key "$key" in contents: $item. '
            'Using the first one found.',
          );
        }
        newData[key] = value;
      } else {
        genUiLogger.warning('Invalid item in dataModelUpdate contents: $item');
      }
    }
    return newData;
  }

  dynamic _getValue(dynamic current, List<String> segments) {
    if (segments.isEmpty) {
      return current;
    }

    final segment = segments.first;
    final remaining = segments.sublist(1);

    if (current is Map) {
      return _getValue(current[segment], remaining);
    } else if (current is List) {
      final index = int.tryParse(segment);
      if (index != null && index >= 0 && index < current.length) {
        return _getValue(current[index], remaining);
      }
    }
    return null;
  }

  void _updateValue(dynamic current, List<String> segments, dynamic value) {
    if (segments.isEmpty) {
      return;
    }

    final segment = segments.first;
    final remaining = segments.sublist(1);

    if (current is Map) {
      if (remaining.isEmpty) {
        current[segment] = value;
        return;
      }

      // If we are here, remaining is not empty.
      final nextSegment = remaining.first;
      final isNextSegmentListIndex = nextSegment.startsWith(RegExp(r'^\d+$'));

      var nextNode = current[segment];

      if (isNextSegmentListIndex) {
        if (nextNode is! List) {
          nextNode = <dynamic>[];
          current[segment] = nextNode;
        }
      } else {
        // Next segment is a map key
        if (nextNode is! Map) {
          nextNode = <String, dynamic>{};
          current[segment] = nextNode;
        }
      }
      _updateValue(nextNode, remaining, value);
    } else if (current is List) {
      final index = int.tryParse(segment);
      if (index != null && index >= 0) {
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
          } else if (index == current.length) {
            // If the index is the length, we're adding a new item which
            // should be a map or list based on the next segment.
            if (remaining.first.startsWith(RegExp(r'^\d+$'))) {
              current.add(<dynamic>[]);
            } else {
              current.add(<String, dynamic>{});
            }
            _updateValue(current[index], remaining, value);
          } else {
            throw ArgumentError(
              'Index out of bounds for nested update: index ($index) is '
              'greater than list length (${current.length}).',
            );
          }
        }
      } else {
        genUiLogger.warning('Invalid list index segment: $segment');
      }
    }
  }

  void _notifySubscribers(DataPath path) {
    genUiLogger.info(
      'DataModel._notifySubscribers: notifying '
      '${_subscriptions.length} subscribers for path=$path',
    );
    for (final p in _subscriptions.keys) {
      if (p.startsWith(path) || path.startsWith(p)) {
        genUiLogger.info('  - Notifying subscriber for path=$p');
        final subscriber = _subscriptions[p];
        if (subscriber != null) {
          subscriber.value = getValue<dynamic>(p);
        }
      }
    }
    if (_valueSubscriptions.containsKey(path)) {
      genUiLogger.info('  - Notifying value subscriber for path=$path');
      final subscriber = _valueSubscriptions[path];
      if (subscriber != null) {
        subscriber.value = getValue<dynamic>(path);
      }
    }
  }
}
