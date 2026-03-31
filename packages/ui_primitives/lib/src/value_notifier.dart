// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/animation.dart';
/// @docImport 'package:flutter/widgets.dart';
library;

import 'package:meta/meta.dart';

import 'change_notifier.dart';
import 'error_reporter.dart';
import 'interfaces.dart';
import 'primitives.dart';
import 'private_leak_tracking.dart';

/// A [ChangeNotifier] that holds a single value.
///
/// When [value] is replaced with a new value that is **not equal** to the old
/// value as evaluated by the equality operator (`==`), this class notifies its
/// listeners.
///
/// ## Limitations
///
/// Notifications are triggered based on **equality (`==`)**, not on mutations
/// within the value itself. As a result, changes to mutable objects that do not
/// affect their equality will not cause listeners to be notified.
///
/// For example, a `ValueNotifier<List<int>>` will not notify listeners when
/// the contents of the existing list are modified in-place; it only notifies
/// when a new value is assigned to the `value` property (i.e. `value =
/// newValue`),
/// where equality is determined by `==`.
///
/// Because of this behavior, [ValueNotifier] is best used with immutable data
/// types.
class ValueNotifier<T>
    implements ValueListenable<T>, Listenable, ChangeNotifier {
  final ChangeNotifier _changeNotifier = ChangeNotifier();

  /// Creates a [ChangeNotifier] that wraps this value.
  ValueNotifier(this._value) {
    assert(() {
      if (kTrackMemoryLeaks) {
        debugMaybeDispatchCreated(runtimeType.toString(), this);
      }
      return true;
    }());
  }

  bool _debugDisposed = false;

  static bool debugAssertNotDisposed<T>(ValueNotifier<T> notifier) {
    assert(() {
      if (notifier._debugDisposed) {
        throw FrameworkErrorReporter.instance.createError(
          'A ${notifier.runtimeType} was used after being disposed.\n'
          'Once you have called dispose() on a ${notifier.runtimeType}, it '
          'can no longer be used.',
        );
      }
      return true;
    }());
    return true;
  }

  /// The current value stored in this notifier.
  ///
  /// When the value is replaced with something that is not equal to the old
  /// value as evaluated by the equality operator ==, this class notifies its
  /// listeners.
  @override
  T get value => _value;
  T _value;
  set value(T newValue) {
    if (_value == newValue) {
      return;
    }
    _value = newValue;
    _changeNotifier.notifyListeners();
  }

  @override
  String toString() => '${describeIdentity(this)}($value)';

  @override
  void dispose() {
    assert(() {
      _debugDisposed = true;
      if (kTrackMemoryLeaks) debugMaybeDispatchDisposed(this);
      return true;
    }());

    _changeNotifier.dispose();
  }

  @override
  void addListener(VoidCallback listener) =>
      _changeNotifier.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _changeNotifier.removeListener(listener);

  @override
  @protected
  bool get hasListeners => _changeNotifier.hasListeners;

  @override
  @protected
  void notifyListeners() => _changeNotifier.notifyListeners();
}
