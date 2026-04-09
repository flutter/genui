// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_core/src/common/reactivity.dart';
import 'package:test/test.dart';

void main() {
  group('Reactivity', () {
    test('ValueNotifier notifies listeners', () {
      final ValueNotifier<int> notifier = ValueNotifier(10);
      var callCount = 0;
      notifier.addListener(() => callCount++);

      notifier.value = 20;
      expect(callCount, 1);
      expect(notifier.value, 20);

      notifier.value = 20; // No change
      expect(callCount, 1);
    });

    test('ComputedNotifier tracks dependencies', () {
      final ValueNotifier<int> a = ValueNotifier(1);
      final ValueNotifier<int> b = ValueNotifier(2);
      final ComputedNotifier<int> sum = ComputedNotifier(
        () => a.value + b.value,
      );

      expect(sum.value, 3);

      var callCount = 0;
      sum.addListener(() => callCount++);

      a.value = 10;
      expect(sum.value, 12);
      expect(callCount, 1);

      b.value = 20;
      expect(sum.value, 30);
      expect(callCount, 2);
    });

    test('ComputedNotifier updates dependencies dynamically', () {
      final ValueNotifier<bool> useA = ValueNotifier(true);
      final ValueNotifier<int> a = ValueNotifier(1);
      final ValueNotifier<int> b = ValueNotifier(2);
      final ComputedNotifier<int> result = ComputedNotifier(
        () => useA.value ? a.value : b.value,
      );

      expect(result.value, 1);

      var callCount = 0;
      result.addListener(() => callCount++);

      b.value = 10; // Should not notify as b is not a dependency yet
      expect(callCount, 0);

      useA.value = false;
      expect(result.value, 10);
      expect(callCount, 1);

      a.value = 100; // Should not notify as a is no longer a dependency
      expect(callCount, 1);

      b.value = 20;
      expect(callCount, 2);
      expect(result.value, 20);
    });

    test('batch defers notifications', () {
      final ValueNotifier<int> a = ValueNotifier(1);
      final ValueNotifier<int> b = ValueNotifier(2);
      final ComputedNotifier<int> sum = ComputedNotifier(
        () => a.value + b.value,
      );

      var callCount = 0;
      sum.addListener(() => callCount++);

      batch(() {
        a.value = 10;
        b.value = 20;
        expect(callCount, 0); // Not yet notified
      });

      expect(callCount, 1); // Notified exactly once
      expect(sum.value, 30);
    });

    test('nested batch defers to outermost', () {
      final ValueNotifier<int> a = ValueNotifier(0);
      var callCount = 0;
      a.addListener(() => callCount++);

      batch(() {
        a.value = 1;
        batch(() {
          a.value = 2;
        });
        expect(callCount, 0);
      });

      expect(callCount, 1);
      expect(a.value, 2);
    });

    test('forceNotify notifies even when value unchanged', () {
      final ValueNotifier<int> notifier = ValueNotifier(1);
      var callCount = 0;
      notifier.addListener(() => callCount++);

      notifier.forceNotify();
      expect(callCount, 1);

      notifier.forceNotify();
      expect(callCount, 2);
    });

    test('ComputedNotifier.dispose stops reacting', () {
      final ValueNotifier<int> source = ValueNotifier(1);
      final ComputedNotifier<int> computed = ComputedNotifier(
        () => source.value * 10,
      );

      expect(computed.value, 10);

      computed.dispose();

      // Should not throw or react.
      source.value = 2;
    });
  });
}
