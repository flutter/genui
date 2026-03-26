import 'dart:async';

/// An interface for objects that maintain a list of listeners.
abstract interface class Listenable {
  /// Adds a listener to be notified when the object changes.
  void addListener(void Function() listener);

  /// Removes a listener.
  void removeListener(void Function() listener);
}

/// An interface for objects that hold a value and notify listeners when it changes.
abstract class ValueListenable<T> implements Listenable {
  /// The current value.
  T get value;
}

bool _inBatch = false;
final _pendingNotifiers = <ValueNotifier<dynamic>>{};

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
    final toNotify = _pendingNotifiers.toList();
    _pendingNotifiers.clear();
    for (final notifier in toNotify) {
      notifier._notifyListeners();
    }
  }
}

/// A base class for objects that hold a value and notify listeners when it changes.
class ValueNotifier<T> implements ValueListenable<T> {
  T _value;
  final _listeners = <void Function()>{};

  ValueNotifier(this._value);

  @override
  T get value {
    _DependencyTracker.instance?._reportRead(this);
    return _value;
  }

  set value(T newValue) {
    if (_value == newValue) return;
    _value = newValue;
    notifyListeners();
  }

  @override
  void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  /// Notifies all registered listeners.
  void notifyListeners() {
    if (_inBatch) {
      _pendingNotifiers.add(this);
      return;
    }
    _notifyListeners();
  }

  void _notifyListeners() {
    for (final listener in List<void Function()>.from(_listeners)) {
      if (_listeners.contains(listener)) {
        listener();
      }
    }
  }

  /// Disposes of the notifier and its resources.
  void dispose() {
    _listeners.clear();
    _pendingNotifiers.remove(this);
  }
}

/// A derived notifier that automatically tracks and listens to other [ValueListenable]
/// dependencies, recalculating its value only when they change.
class ComputedNotifier<T> extends ValueNotifier<T> {
  final T Function() _compute;
  final Set<ValueListenable<dynamic>> _dependencies = {};

  ComputedNotifier(this._compute) : super(_compute()) {
    _updateDependencies();
  }

  void _updateDependencies() {
    final tracker = _DependencyTracker();
    final newValue = tracker.track(_compute);

    final newDeps = tracker.dependencies;
    
    // Unsubscribe from old dependencies no longer needed
    for (final dep in _dependencies.difference(newDeps)) {
      dep.removeListener(_onDependencyChanged);
    }
    
    // Subscribe to new dependencies
    for (final dep in newDeps.difference(_dependencies)) {
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
  T get value {
    // If we have no listeners, we might want to re-evaluate on every read
    // to ensure we're fresh, but usually, Computed is used with listeners.
    // For now, let's just return the cached value and rely on dependencies.
    return super.value;
  }

  @override
  void dispose() {
    for (final dep in _dependencies) {
      dep.removeListener(_onDependencyChanged);
    }
    _dependencies.clear();
    super.dispose();
  }
}

class _DependencyTracker {
  static _DependencyTracker? instance;
  final Set<ValueListenable<dynamic>> dependencies = {};

  T track<T>(T Function() callback) {
    final previous = instance;
    instance = this;
    try {
      return callback();
    } finally {
      instance = previous;
    }
  }

  void _reportRead(ValueListenable<dynamic> listenable) {
    dependencies.add(listenable);
  }
}
