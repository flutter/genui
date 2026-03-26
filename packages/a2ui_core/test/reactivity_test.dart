import 'package:test/test.dart';
import 'package:a2ui_core/src/common/reactivity.dart';

void main() {
  group('Reactivity', () {
    test('ValueNotifier notifies listeners', () {
      final notifier = ValueNotifier(10);
      int callCount = 0;
      notifier.addListener(() => callCount++);

      notifier.value = 20;
      expect(callCount, 1);
      expect(notifier.value, 20);

      notifier.value = 20; // No change
      expect(callCount, 1);
    });

    test('ComputedNotifier tracks dependencies', () {
      final a = ValueNotifier(1);
      final b = ValueNotifier(2);
      final sum = ComputedNotifier(() => a.value + b.value);

      expect(sum.value, 3);

      int callCount = 0;
      sum.addListener(() => callCount++);

      a.value = 10;
      expect(sum.value, 12);
      expect(callCount, 1);

      b.value = 20;
      expect(sum.value, 30);
      expect(callCount, 2);
    });

    test('ComputedNotifier updates dependencies dynamically', () {
      final useA = ValueNotifier(true);
      final a = ValueNotifier(1);
      final b = ValueNotifier(2);
      final result = ComputedNotifier(() => useA.value ? a.value : b.value);

      expect(result.value, 1);

      int callCount = 0;
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
      final a = ValueNotifier(1);
      final b = ValueNotifier(2);
      final sum = ComputedNotifier(() => a.value + b.value);

      int callCount = 0;
      sum.addListener(() => callCount++);

      batch(() {
        a.value = 10;
        b.value = 20;
        expect(callCount, 0); // Not yet notified
      });

      expect(callCount, 1); // Notified exactly once
      expect(sum.value, 30);
    });
  });
}
