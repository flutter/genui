// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../listenable/notifiers.dart' as notifiers;

/// Alias for [notifiers.GenUiListenable].
typedef Listenable = notifiers.GenUiListenable;

/// Alias for [notifiers.GenUiValueListenable].
typedef ValueListenable<T> = notifiers.GenUiValueListenable<T>;

bool _inBatch = false;
final _pendingNotifiers = <ValueNotifier<Object?>>{};

/// Executes [callback] and defers notifications until it completes.
void batch(void Function() callback) {
  if (_inBatch) {
    callback();
    return;
  }

  _inBatch = true;
  try {
    callback();
  } finally {
    _inBatch = false;
    final List<ValueNotifier<Object?>> toNotify = _pendingNotifiers.toList();
    _pendingNotifiers.clear();
    for (final notifier in toNotify) {
      notifier.forceNotify();
    }
  }
}

/// A value holder that notifies listeners when the value changes.
///
/// Extends [notifiers.ChangeNotifier] for robust listener management and adds
/// batch-aware notification and automatic dependency tracking for use with
/// [ComputedNotifier].
class ValueNotifier<T> extends notifiers.ChangeNotifier
    implements notifiers.GenUiValueListenable<T> {
  T _value;

  ValueNotifier(this._value);

  @override
  T get value {
    _DependencyTracker.instance?._reportRead(this);
    return _value;
  }

  set value(T newValue) {
    if (_value == newValue) return;
    _value = newValue;
    if (_inBatch) {
      _pendingNotifiers.add(this);
      return;
    }
    notifyListeners();
  }

  /// Notifies listeners unconditionally, even if the value hasn't changed.
  ///
  /// Use this when the held value is a mutable container (e.g. a [Map] or
  /// [List]) whose contents changed in place without changing the reference.
  void forceNotify() {
    if (_inBatch) {
      _pendingNotifiers.add(this);
      return;
    }
    notifyListeners();
  }
}

/// A derived notifier that automatically tracks and listens to other
/// [ValueListenable] dependencies, recalculating its value only when they
/// change.
class ComputedNotifier<T> extends ValueNotifier<T> {
  final T Function() _compute;
  final Set<notifiers.GenUiValueListenable<Object?>> _dependencies = {};

  ComputedNotifier(this._compute) : super(_initialValue(_compute)) {
    _subscribePendingDeps();
  }

  // Stack-based pending deps to handle reentrant ComputedNotifier creation
  // (e.g. when _compute itself creates a nested ComputedNotifier).
  static final List<Set<notifiers.GenUiValueListenable<Object?>>>
  _pendingDepsStack = [];

  static T _initialValue<T>(T Function() compute) {
    final tracker = _DependencyTracker();
    final T value = tracker.track(compute);
    _pendingDepsStack.add(tracker.dependencies);
    return value;
  }

  void _subscribePendingDeps() {
    final Set<notifiers.GenUiValueListenable<Object?>> deps = _pendingDepsStack
        .removeLast();
    for (final dep in deps) {
      dep.addListener(_onDependencyChanged);
    }
    _dependencies.addAll(deps);
  }

  void _updateDependencies() {
    final tracker = _DependencyTracker();
    final T newValue = tracker.track(_compute);

    final Set<notifiers.GenUiValueListenable<Object?>> newDeps =
        tracker.dependencies;

    // Unsubscribe from old dependencies no longer needed.
    for (final notifiers.GenUiValueListenable<Object?> dep
        in _dependencies.difference(newDeps)) {
      dep.removeListener(_onDependencyChanged);
    }

    // Subscribe to new dependencies.
    for (final notifiers.GenUiValueListenable<Object?> dep
        in newDeps.difference(_dependencies)) {
      dep.addListener(_onDependencyChanged);
    }

    _dependencies.clear();
    _dependencies.addAll(newDeps);

    super.value = newValue;
  }

  void _onDependencyChanged() {
    _updateDependencies();
  }

  @override
  void dispose() {
    for (final notifiers.GenUiValueListenable<Object?> dep in _dependencies) {
      dep.removeListener(_onDependencyChanged);
    }
    _dependencies.clear();
    super.dispose();
  }
}

class _DependencyTracker {
  static _DependencyTracker? instance;
  final Set<notifiers.GenUiValueListenable<Object?>> dependencies = {};

  T track<T>(T Function() callback) {
    final _DependencyTracker? previous = instance;
    instance = this;
    try {
      return callback();
    } finally {
      instance = previous;
    }
  }

  void _reportRead(notifiers.GenUiValueListenable<Object?> listenable) {
    dependencies.add(listenable);
  }
}
