import '../common/data_path.dart';
import '../common/reactivity.dart';
import '../common/errors.dart';
import 'dart:collection';
import 'package:collection/collection.dart';

/// A standalone, observable data store representing the client-side state.
/// It handles JSON Pointer path resolution and subscription management.
class DataModel {
  dynamic _data;
  final Map<String, WeakReference<ValueNotifier<dynamic>>> _notifiers = {};

  DataModel([dynamic initialData]) : _data = initialData ?? {};

  /// Synchronously gets data at a specific JSON pointer path.
  dynamic get(String path) {
    final dataPath = DataPath.parse(path);
    if (dataPath.isEmpty) return _data;

    dynamic current = _data;
    for (final segment in dataPath.segments) {
      if (current == null) return null;
      if (current is Map) {
        current = current[segment];
      } else if (current is List) {
        final index = int.tryParse(segment);
        if (index == null || index < 0 || index >= current.length) return null;
        current = current[index];
      } else {
        return null;
      }
    }
    return current;
  }

  /// Updates data at a specific path and notifies listeners.
  void set(String path, dynamic value) {
    final dataPath = DataPath.parse(path);
    
    batch(() {
      if (dataPath.isEmpty) {
        _data = value;
      } else {
        _data ??= {};
        dynamic current = _data;
        for (int i = 0; i < dataPath.segments.length - 1; i++) {
          final segment = dataPath.segments[i];
          final nextSegment = dataPath.segments[i + 1];
          final isNextNumeric = int.tryParse(nextSegment) != null;

          if (current is Map) {
            if (!current.containsKey(segment) || current[segment] == null) {
              current[segment] = isNextNumeric ? [] : {};
            }
            current = current[segment];
          } else if (current is List) {
            final index = int.tryParse(segment);
            if (index == null) {
              throw A2uiDataError("Cannot use non-numeric segment '$segment' on a list.", path: path);
            }
            while (current.length <= index) {
              current.add(null);
            }
            if (current[index] == null) {
              current[index] = isNextNumeric ? [] : {};
            }
            current = current[index];
          } else {
            throw A2uiDataError("Cannot set path '$path': intermediate segment '$segment' is a primitive.", path: path);
          }
        }

        final lastSegment = dataPath.segments.last;
        if (current is Map) {
          if (value == null) {
            current.remove(lastSegment);
          } else {
            current[lastSegment] = value;
          }
        } else if (current is List) {
          final index = int.tryParse(lastSegment);
          if (index == null) {
            throw A2uiDataError("Cannot use non-numeric segment '$lastSegment' on a list.", path: path);
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
    String normalizedPath = DataPath.parse(path).toString();
    if (normalizedPath == '') normalizedPath = '/';
    final ref = _notifiers[normalizedPath];
    if (ref != null) {
      final notifier = ref.target;
      if (notifier != null) {
        return notifier as ValueListenable<T?>;
      }
    }

    final notifier = ValueNotifier<T?>(get(normalizedPath));
    _notifiers[normalizedPath] = WeakReference(notifier);
    _pruneNotifiers();
    return notifier;
  }

  void _notifyPathAndRelated(DataPath dataPath) {
    final normalizedPath = dataPath.toString();
    
    // Notify all active notifiers that are related to this path
    for (final entryPath in _notifiers.keys.toList()) {
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
    final ref = _notifiers[path];
    if (ref == null) return;
    
    final notifier = ref.target;
    if (notifier == null) {
      _notifiers.remove(path);
      return;
    }

    final newValue = get(path);
    notifier.value = newValue;
    notifier.notifyListeners();
  }

  void _pruneNotifiers() {
    _notifiers.removeWhere((key, ref) => ref.target == null);
  }

  void dispose() {
    for (final ref in _notifiers.values) {
      ref.target?.dispose();
    }
    _notifiers.clear();
  }
}
