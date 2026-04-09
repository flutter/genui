// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Read-only interface for subscribing to discrete events.
///
/// This is the event equivalent of `ValueListenable` — models expose this
/// interface publicly while owning the mutable [EventNotifier] internally.
///
/// Unlike `ValueListenable`, an [EventListenable] has no "current value."
/// It represents things that happen (surface created, action dispatched)
/// rather than state that changes (data model values, resolved props).
abstract interface class EventListenable<T> {
  /// Registers [listener] to be called whenever an event is emitted.
  void addListener(void Function(T event) listener);

  /// Removes a previously registered [listener].
  void removeListener(void Function(T event) listener);
}

/// A synchronous, typed event emitter for discrete events.
///
/// Dart equivalent of web_core's `EventEmitter<T>`. Use this for lifecycle
/// events and notifications where there is no meaningful "current value" —
/// only the fact that something happened.
///
/// Every call to [emit] notifies all listeners, regardless of payload
/// equality. This avoids the pitfall of `ValueNotifier` suppressing
/// duplicate notifications via `==`.
class EventNotifier<T> implements EventListenable<T> {
  final List<void Function(T event)> _listeners = [];

  /// Emits an event to all registered listeners.
  void emit(T event) {
    // Iterate over a copy to allow listeners to remove themselves.
    for (final void Function(T event) listener in List.of(_listeners)) {
      listener(event);
    }
  }

  @override
  void addListener(void Function(T event) listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(void Function(T event) listener) {
    _listeners.remove(listener);
  }

  /// Removes all listeners.
  void dispose() {
    _listeners.clear();
  }
}
