// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:a2ui_core/a2ui_core.dart' as core;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../model/data_model.dart';
import '../primitives/logging.dart';

export '../model/data_model.dart' show resolveContext;

/// A builder widget that simplifies handling of nullable `ValueListenable`s.
///
/// Listens to a `ValueListenable<T?>` and rebuilds its child whenever the
/// value changes. Returns `SizedBox.shrink()` for null; otherwise calls
/// [builder] with the non-null value.
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

/// A widget that binds to a value in the [DataContext] and rebuilds when it
/// changes.
///
/// Subclasses provide type-specific conversion via [BoundValueState.convert].
abstract class BoundValue<T> extends StatefulWidget {
  /// Creates a [BoundValue].
  const BoundValue({
    super.key,
    required this.dataContext,
    required this.value,
    required this.builder,
  });

  /// The [DataContext] to resolve the value against.
  final DataContext dataContext;

  /// The value definition (literal, path, or function call).
  final Object? value;

  /// The builder function to call when the value changes.
  final Widget Function(BuildContext context, T? value) builder;

  @override
  State<BoundValue<T>> createState();
}

/// Backing state for [BoundValue]. Manages a preact_signals signal that
/// mirrors the resolved value. Function-call values (`{call: ...}`) are
/// driven by a [StreamSubscription] that pushes into the signal.
abstract class BoundValueState<T, W extends BoundValue<T>> extends State<W> {
  late core.ReadonlySignal<T?> _signal;
  StreamSubscription<Object?>? _streamSub;
  void Function()? _disposeBridge;

  @override
  void initState() {
    super.initState();
    _setupSignal();
  }

  @override
  void didUpdateWidget(W oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value ||
        widget.dataContext != oldWidget.dataContext) {
      _disposeSignal();
      _setupSignal();
    }
  }

  @override
  void dispose() {
    _disposeSignal();
    super.dispose();
  }

  void _setupSignal() {
    final Object? raw = widget.value;

    if (raw is Map && raw.containsKey('path')) {
      final path = DataPath(raw['path'] as String);
      final ValueListenable<Object?> source = widget.dataContext
          .subscribe<Object?>(path);
      // Bridge the legacy ValueListenable facade to a signal so the
      // signal-backed BoundValue implementation can stay granular.
      final core.Signal<T?> bridge = core.signal<T?>(convert(source.value));

      void listener() {
        bridge.set(convert(source.value), force: true);
      }

      source.addListener(listener);
      _disposeBridge = () {
        source.removeListener(listener);
        final currentSource = source;
        if (currentSource is ChangeNotifier) {
          (currentSource as ChangeNotifier).dispose();
        }
      };
      _signal = bridge;
    } else if (raw is Map && raw.containsKey('call')) {
      // Function-call resolution stays Stream-based for now; bridge to signal.
      final core.Signal<T?> s = core.signal<T?>(null);
      _streamSub = widget.dataContext
          .resolve(raw)
          .listen(
            (Object? v) => s.value = convert(v),
            onError: (Object error) {
              genUiLogger.warning('Error in Bound stream', error);
            },
          );
      _signal = s;
    } else {
      _signal = core.signal<T?>(convert(raw));
    }
  }

  void _disposeSignal() {
    _streamSub?.cancel();
    _streamSub = null;
    _disposeBridge?.call();
    _disposeBridge = null;
    // preact_signals don't require explicit disposal; subscriptions are torn
    // down when the consuming Effect (in _SignalBuilder) is disposed.
  }

  /// Converts a raw resolved value into the typed [T?].
  T? convert(Object? value);

  @override
  Widget build(BuildContext context) {
    return _SignalBuilder<T?>(
      signal: _signal,
      builder: (ctx, value) => widget.builder(ctx, value),
    );
  }
}

/// Subscribes to a preact_signals [core.ReadonlySignal] and rebuilds when it
/// changes. Stand-in for `Watch` from a signals-Flutter package, since
/// `signals_flutter` is built on a different (incompatible) signals library.
class _SignalBuilder<T> extends StatefulWidget {
  const _SignalBuilder({required this.signal, required this.builder});

  final core.ReadonlySignal<T> signal;
  final Widget Function(BuildContext context, T value) builder;

  @override
  State<_SignalBuilder<T>> createState() => _SignalBuilderState<T>();
}

class _SignalBuilderState<T> extends State<_SignalBuilder<T>> {
  late T _value;
  void Function()? _disposeEffect;
  bool _initialRun = true;

  @override
  void initState() {
    super.initState();
    _value = widget.signal.peek();
    _subscribe();
  }

  @override
  void didUpdateWidget(_SignalBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.signal != oldWidget.signal) {
      _disposeEffect?.call();
      _initialRun = true;
      _value = widget.signal.peek();
      _subscribe();
    }
  }

  void _subscribe() {
    _disposeEffect = core.effect(() {
      final T newValue = widget.signal.value;
      // First run is the dependency-tracking pass; value already set from peek.
      if (_initialRun) {
        _initialRun = false;
        return;
      }
      if (mounted) {
        setState(() => _value = newValue);
      }
    });
  }

  @override
  void dispose() {
    _disposeEffect?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _value);
}

/// Binds to a [String] value.
class BoundString extends BoundValue<String> {
  /// Creates a [BoundString].
  const BoundString({
    super.key,
    required super.dataContext,
    required super.value,
    required super.builder,
  });

  @override
  State<BoundString> createState() => _BoundStringState();
}

class _BoundStringState extends BoundValueState<String, BoundString> {
  @override
  String? convert(Object? value) => value?.toString();
}

/// Binds to a [bool] value.
class BoundBool extends BoundValue<bool> {
  /// Creates a [BoundBool].
  const BoundBool({
    super.key,
    required super.dataContext,
    required super.value,
    required super.builder,
  });

  @override
  State<BoundBool> createState() => _BoundBoolState();
}

class _BoundBoolState extends BoundValueState<bool, BoundBool> {
  @override
  bool? convert(Object? value) {
    if (value is bool) return value;
    if (value is String) {
      if (value.toLowerCase() == 'true') return true;
      if (value.toLowerCase() == 'false') return false;
    }
    if (value is num) return value != 0;
    return null;
  }
}

/// Binds to a [num] value.
class BoundNumber extends BoundValue<num> {
  /// Creates a [BoundNumber].
  const BoundNumber({
    super.key,
    required super.dataContext,
    required super.value,
    required super.builder,
  });

  @override
  State<BoundNumber> createState() => _BoundNumberState();
}

class _BoundNumberState extends BoundValueState<num, BoundNumber> {
  @override
  num? convert(Object? value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }
}

/// Binds to a [List] of objects.
class BoundList extends BoundValue<List<Object?>> {
  /// Creates a [BoundList].
  const BoundList({
    super.key,
    required super.dataContext,
    required super.value,
    required super.builder,
  });

  @override
  State<BoundList> createState() => _BoundListState();
}

class _BoundListState extends BoundValueState<List<Object?>, BoundList> {
  @override
  List<Object?>? convert(Object? value) {
    if (value is List) return value.cast<Object?>();
    return null;
  }
}

/// Binds to any [Object] value.
class BoundObject extends BoundValue<Object> {
  /// Creates a [BoundObject].
  const BoundObject({
    super.key,
    required super.dataContext,
    required super.value,
    required super.builder,
  });

  @override
  State<BoundObject> createState() => _BoundObjectState();
}

class _BoundObjectState extends BoundValueState<Object, BoundObject> {
  @override
  Object? convert(Object? value) => value;
}
