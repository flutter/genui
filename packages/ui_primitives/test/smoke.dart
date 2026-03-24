import 'package:test/test.dart';
import 'package:ui_primitives/ui_primitives.dart';

void main() {
  test('smoke', () {
    final ValueNotifier<int> notifier = ValueNotifier(1);
    addTearDown(notifier.dispose);
    var count = 0;
    notifier.addListener(() => count++);

    expect(notifier.value, 1);
    expect(count, 0);

    notifier.value = 2;
    expect(notifier.value, 2);
    expect(count, 1);
  });
}
