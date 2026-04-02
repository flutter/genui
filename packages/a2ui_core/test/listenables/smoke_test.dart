// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_core/a2ui_core.dart';
import 'package:test/test.dart';

// ignore: unused_element, tests that ValueNotifier can be implemented.
class _ValueNotifierImplementation<T> implements ValueNotifier<T> {
  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  @override
  T get value => throw UnimplementedError();

  @override
  void dispose() {}

  @override
  set value(T newValue) {}

  @override
  bool get hasListeners => throw UnimplementedError();

  @override
  void notifyListeners() {}
}

// ignore: unused_element, tests that ValueNotifier can be extended.
class _ValueNotifierExtention<T> extends ValueNotifier<T> {
  _ValueNotifierExtention(super.value);
}

// ignore: unused_element, tests that ChangeNotifier can be implemented.
class _ChangeNotifierImplementation implements ChangeNotifier {
  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  @override
  void dispose() {}

  @override
  bool get hasListeners => throw UnimplementedError();

  @override
  void notifyListeners() {}
}

// ignore: unused_element, tests that ChangeNotifier can be extended.
class _ChangeNotifierExtention extends ChangeNotifier {}

void main() {
  test('ValueNotifier basic functionality is working', () {
    final ValueNotifier<int> notifier = ValueNotifier(1);
    addTearDown(notifier.dispose);
    var count = 0;
    notifier.addListener(() => count++);

    expect(notifier, isA<ValueListenable<int>>());
    expect(notifier.value, 1);
    expect(count, 0);

    notifier.value = 2;
    expect(notifier.value, 2);
    expect(count, 1);
  });

  test('ChangeNotifier basic functionality is working', () {
    final notifier = ChangeNotifier();
    addTearDown(notifier.dispose);
    var count = 0;
    notifier.addListener(() => count++);

    expect(notifier, isA<Listenable>());
    expect(count, 0);

    // ignore: invalid_use_of_protected_member
    notifier.notifyListeners();
    expect(count, 1);
  });
}
