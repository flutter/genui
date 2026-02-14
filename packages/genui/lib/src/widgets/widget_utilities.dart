// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../functions/expression_parser.dart';
import '../model/data_model.dart';
import '../primitives/simple_items.dart';

/// A builder widget that simplifies handling of nullable `ValueListenable`s.
///
/// This widget listens to a `ValueListenable<T?>` and rebuilds its child
/// whenever the value changes. If the value is `null`, it returns a
/// `SizedBox.shrink()`, effectively hiding the child. If the value is not
/// `null`, it calls the `builder` function with the non-nullable value.
class OptionalValueBuilder<T> extends StatelessWidget {
  /// The `ValueListenable` to listen to.
  final ValueListenable<T?> listenable;

  /// The builder function to call when the value is not `null`.
  final Widget Function(BuildContext context, T value) builder;

  /// Creates an `OptionalValueBuilder`.
  const OptionalValueBuilder({
    super.key,
    required this.listenable,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<T?>(
      valueListenable: listenable,
      builder: (context, value, _) {
        if (value == null) return const SizedBox.shrink();
        return builder(context, value);
      },
    );
  }
}

/// Extension methods for [DataContext] to simplify data binding.
extension DataContextExtensions on DataContext {
  /// Subscribes to a string value, which can be a literal or a data-bound path.
  ///
  /// This method is robust against type mismatches in the data model. If the
  /// underlying value is not a String, it will be converted using [toString].
  ValueNotifier<String?> subscribeToString(Object? value) {
    if (value is Map && value.containsKey('path')) {
      final ValueNotifier<Object?> raw = subscribe<Object?>(
        value['path'] as String,
      );

      return _ToStringNotifier(raw);
    }
    if (value is String && !value.contains(r'${')) {
      return ValueNotifier<String?>(value);
    }
    return subscribe<String>(value);
  }

  /// Subscribes to a boolean value, which can be a literal or a data-bound
  /// path.
  ValueNotifier<bool?> subscribeToBool(Object? value) {
    if (value is Map && value.containsKey('path')) {
      final ValueNotifier<Object?> raw = subscribe<Object?>(
        value['path'] as String,
      );
      return _ToBoolNotifier(raw);
    }
    return subscribe<bool>(value);
  }

  /// Subscribes to a list of objects, which can be a literal or a data-bound
  /// path.
  ValueNotifier<List<Object?>?> subscribeToObjectArray(Object? value) {
    return subscribe<List<Object?>>(value);
  }

  /// Subscribes to a number value, which can be a literal or a data-bound
  /// path.
  ValueNotifier<num?> subscribeToNumber(Object? value) {
    if (value is Map && value.containsKey('path')) {
      final ValueNotifier<Object?> raw = subscribe<Object?>(
        value['path'] as String,
      );
      return _ToNumberNotifier(raw);
    }
    return subscribe<num>(value);
  }
}

class _ToStringNotifier extends ValueNotifier<String?> {
  _ToStringNotifier(this._source) : super(_source.value?.toString()) {
    _source.addListener(_update);
  }

  final ValueNotifier<Object?> _source;

  void _update() {
    super.value = _source.value?.toString();
  }

  @override
  void dispose() {
    _source.removeListener(_update);
    super.dispose();
  }
}

class _ToBoolNotifier extends ValueNotifier<bool?> {
  _ToBoolNotifier(this._source) : super(_convert(_source.value)) {
    _source.addListener(_update);
  }

  final ValueNotifier<Object?> _source;

  static bool? _convert(Object? value) {
    if (value is bool) return value;
    if (value is String) {
      if (value.toLowerCase() == 'true') return true;
      if (value.toLowerCase() == 'false') return false;
    }
    if (value is num) return value != 0;
    return null;
  }

  void _update() {
    super.value = _convert(_source.value);
  }

  @override
  void dispose() {
    _source.removeListener(_update);
    super.dispose();
  }
}

class _ToNumberNotifier extends ValueNotifier<num?> {
  _ToNumberNotifier(this._source) : super(_convert(_source.value)) {
    _source.addListener(_update);
  }

  final ValueNotifier<Object?> _source;

  static num? _convert(Object? value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  void _update() {
    super.value = _convert(_source.value);
  }

  @override
  void dispose() {
    _source.removeListener(_update);
    super.dispose();
  }
}

/// Resolves a context map definition against a [DataContext].
///
JsonMap resolveContext(DataContext dataContext, JsonMap? contextDefinition) {
  final resolved = <String, Object?>{};
  if (contextDefinition == null) return resolved;

  final parser = ExpressionParser(dataContext);

  for (final MapEntry<String, Object?> entry in contextDefinition.entries) {
    final String key = entry.key;
    final Object? value = entry.value;
    if (value is String) {
      resolved[key] = parser.parse(value);
    } else if (value is Map && value.containsKey('path')) {
      resolved[key] = dataContext.getValue(value['path'] as String);
    } else {
      resolved[key] = value;
    }
  }
  return resolved;
}
