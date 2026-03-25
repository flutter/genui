// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:ui_primitives/ui_primitives.dart';

// ignore: unused_element, tests that ValueNotifier can be implemented.
class _ValueNotifierOtherImplementaion<T> implements ValueNotifier<T> {
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
}

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
}
