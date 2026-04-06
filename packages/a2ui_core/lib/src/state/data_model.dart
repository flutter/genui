// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../common/data_path.dart';
import '../common/errors.dart';
import '../common/reactivity.dart';

/// The maximum list index that auto-vivification will expand to.
///
/// Prevents OOM from paths like `/data/999999999` which would otherwise
/// allocate a billion-element list.
const int maxAutoVivifyIndex = 10000;

/// A standalone, observable data store representing the client-side state.
/// It handles JSON Pointer path resolution and subscription management.
class DataModel {
  dynamic _data;
  final Map<String, WeakReference<ValueNotifier<dynamic>>> _notifiers = {};

  DataModel([Object? initialData]) : _data = initialData ?? <String, dynamic>{};

  /// Synchronously gets data at a specific JSON pointer path.
  dynamic get(String path) {
    final dataPath = DataPath.parse(path);
    if (dataPath.isEmpty) return _data;

    dynamic current = _data;
    for (final String segment in dataPath.segments) {
      if (current == null) return null;
      if (current is Map) {
        current = current[segment];
      } else if (current is List) {
        final int? index = int.tryParse(segment);
        if (index == null || index < 0 || index >= current.length) return null;
        current = current[index];
      } else {
        return null;
      }
    }
    return current;
  }

  /// Updates data at a specific path and notifies listeners.
  void set(String path, Object? value) {
    final dataPath = DataPath.parse(path);

    batch(() {
      if (dataPath.isEmpty) {
        _data = value;
      } else {
        _data ??= <String, dynamic>{};
        dynamic current = _data;
        for (var i = 0; i < dataPath.segments.length - 1; i++) {
          final String segment = dataPath.segments[i];
          final String nextSegment = dataPath.segments[i + 1];
          final isNextNumeric = int.tryParse(nextSegment) != null;

          if (current is Map) {
            if (!current.containsKey(segment) || current[segment] == null) {
              current[segment] = isNextNumeric
                  ? <dynamic>[]
                  : <String, dynamic>{};
            }
            current = current[segment];
          } else if (current is List) {
            final int? index = int.tryParse(segment);
            if (index == null) {
              throw A2uiDataError(
                "Cannot use non-numeric segment '$segment' on a list.",
                path: path,
              );
            }
            if (index < 0 || index > maxAutoVivifyIndex) {
              throw A2uiDataError(
                'List index out of bounds: $index (max $maxAutoVivifyIndex)',
                path: path,
              );
            }
            while (current.length <= index) {
              current.add(null);
            }
            if (current[index] == null) {
              current[index] = isNextNumeric
                  ? <dynamic>[]
                  : <String, dynamic>{};
            }
            current = current[index];
          } else {
            throw A2uiDataError(
              "Cannot set path '$path': intermediate segment '$segment' is a "
              'primitive.',
              path: path,
            );
          }
        }

        final String lastSegment = dataPath.segments.last;
        if (current is Map) {
          if (value == null) {
            current.remove(lastSegment);
          } else {
            current[lastSegment] = value;
          }
        } else if (current is List) {
          final int? index = int.tryParse(lastSegment);
          if (index == null) {
            throw A2uiDataError(
              "Cannot use non-numeric segment '$lastSegment' on a list.",
              path: path,
            );
          }
          if (index < 0 || index > maxAutoVivifyIndex) {
            throw A2uiDataError(
              'List index out of bounds: $index (max $maxAutoVivifyIndex)',
              path: path,
            );
          }
          while (current.length <= index) {
            current.add(null);
          }
          current[index] = value;
        }
      }

      _notifyPathAndRelated(dataPath);
    });
  }

  /// Returns a [ValueListenable] for a specific path.
  /// Internally cached using a [WeakReference] to prevent leaks.
  ValueListenable<T?> watch<T>(String path) {
    var normalizedPath = DataPath.parse(path).toString();
    if (normalizedPath == '') normalizedPath = '/';
    final WeakReference<ValueNotifier<dynamic>>? ref =
        _notifiers[normalizedPath];
    if (ref != null) {
      final ValueNotifier<dynamic>? notifier = ref.target;
      if (notifier != null) {
        return notifier as ValueListenable<T?>;
      }
    }

    final notifier = ValueNotifier<T?>(get(normalizedPath) as T?);
    _notifiers[normalizedPath] = WeakReference(notifier);
    _pruneNotifiers();
    return notifier;
  }

  void _notifyPathAndRelated(DataPath dataPath) {
    final normalizedPath = dataPath.toString();

    // Notify all active notifiers that are related to this path
    for (final String entryPath in _notifiers.keys.toList()) {
      if (entryPath == '/' || entryPath == '') {
        _getAndNotify(entryPath);
        continue;
      }

      if (entryPath == normalizedPath) {
        _getAndNotify(entryPath);
      } else if (normalizedPath.startsWith('$entryPath/')) {
        _getAndNotify(entryPath);
      } else if (entryPath.startsWith('$normalizedPath/')) {
        _getAndNotify(entryPath);
      }
    }
  }

  void _getAndNotify(String path) {
    final WeakReference<ValueNotifier<dynamic>>? ref = _notifiers[path];
    if (ref == null) return;

    final ValueNotifier<dynamic>? notifier = ref.target;
    if (notifier == null) {
      _notifiers.remove(path);
      return;
    }

    final Object? newValue = get(path);
    final Object? oldValue = notifier.value;
    if (identical(oldValue, newValue)) {
      // The value is the same object reference (e.g. a mutated Map/List).
      // Force notification since the setter's equality check would skip it.
      notifier.forceNotify();
    } else {
      notifier.value = newValue;
    }
  }

  void _pruneNotifiers() {
    _notifiers.removeWhere((key, ref) => ref.target == null);
  }

  void dispose() {
    for (final WeakReference<ValueNotifier<dynamic>> ref in _notifiers.values) {
      ref.target?.dispose();
    }
    _notifiers.clear();
  }
}
