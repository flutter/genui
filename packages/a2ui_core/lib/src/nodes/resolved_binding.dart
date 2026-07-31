// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A resolved two-way value in a node's props: a snapshot of the current
/// value, plus a write capability when (and only when) the payload bound a
/// data path.
///
/// Not to be confused with `DataBinding`, the wire model of the
/// `{"path": ...}` payload.
///
/// `set` is null when the payload supplied a literal or a function call, so
/// an unchecked write does not compile under sound null safety. A null `set`
/// maps directly onto disabled-control idioms (`onChanged: null`).
///
/// The snapshot is pinned at emission: a new binding is emitted through the
/// node's props whenever the underlying value changes, so reading `value`
/// never observes a state no emission delivered.
final class ResolvedBinding<T> {
  final T value;
  final void Function(T)? set;

  const ResolvedBinding(this.value, {this.set});

  /// Whether writes have a destination (the payload bound a data path).
  bool get writable => set != null;

  /// Bindings compare by snapshot value and writability, so the shallow
  /// comparison in the node's `setProps` can suppress no-op updates even
  /// though each update constructs a new binding instance.
  @override
  bool operator ==(Object other) =>
      other is ResolvedBinding &&
      writable == other.writable &&
      _valueEquals(value, other.value);

  @override
  int get hashCode => Object.hash(_valueHash(value), writable);
}

bool _valueEquals(Object? a, Object? b) {
  if (identical(a, b)) return true;
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_valueEquals(a[i], b[i])) return false;
    }
    return true;
  }
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final MapEntry<Object?, Object?> entry in a.entries) {
      if (!b.containsKey(entry.key) ||
          !_valueEquals(entry.value, b[entry.key])) {
        return false;
      }
    }
    return true;
  }
  return a == b;
}

int _valueHash(Object? value) {
  if (value is List) return Object.hashAll(value.map(_valueHash));
  if (value is Map) {
    return Object.hashAllUnordered(
      value.entries.map((e) => Object.hash(e.key, _valueHash(e.value))),
    );
  }
  return value.hashCode;
}
