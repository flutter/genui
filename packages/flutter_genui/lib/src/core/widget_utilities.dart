// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
  ValueNotifier<T?> _subscribeToValue<T>(JsonMap? ref, String literalKey) {
    if (ref == null) return ValueNotifier<T?>(null);
    final path = ref['path'] as String?;
    final literal = ref[literalKey];

    if (path != null) {
      if (literal != null) {
        update(path, literal);
      }
      return subscribe<T>(path);
    }

    return ValueNotifier<T?>(literal as T?);
  }

  /// Subscribes to a string value, which can be a literal or a data-bound path.
  ValueNotifier<String?> subscribeToString(JsonMap? ref) {
    return _subscribeToValue<String>(ref, 'literalString');
  }

  /// Subscribes to a list of strings, which can be a literal or a data-bound
  /// path.
  ValueNotifier<List<dynamic>?> subscribeToStringArray(JsonMap? ref) {
    return _subscribeToValue<List<dynamic>>(ref, 'literalStringArray');
  }
}

/// Resolves a context map definition against a [DataContext].
JsonMap resolveContext(
  DataContext dataContext,
  List<Object?> contextDefinitions,
) {
  final resolved = <String, Object?>{};
  for (final contextEntry in contextDefinitions) {
    final entry = contextEntry as JsonMap;
    final key = entry['key']! as String;
    resolved[key] = dataContext.getValue(entry['path'] as String);
  }
  return resolved;
}
