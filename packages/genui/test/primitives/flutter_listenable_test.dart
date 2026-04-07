import 'package:a2ui_core/a2ui_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/src/primitives/flutter_listenable.dart';

class TestGenUiListenable extends GenUiListenable {
  int addListenerCount = 0;
  int removeListenerCount = 0;
  VoidCallback? lastAddedListener;
  VoidCallback? lastRemovedListener;

  @override
  void addListener(VoidCallback listener) {
    addListenerCount++;
    lastAddedListener = listener;
  }

  @override
  void removeListener(VoidCallback listener) {
    removeListenerCount++;
    lastRemovedListener = listener;
  }
}

void main() {
  group('FlutterListenable', () {
    test('adapter registers and unregisters listeners correctly', () {
      final listenable = TestGenUiListenable();
      final adapter = listenable.listenable();

      expect(adapter, isA<Listenable>());
      expect(adapter, isA<FlutterListenableAdapter>());

      void listener() {}

      adapter.addListener(listener);
      expect(listenable.addListenerCount, 1);
      expect(listenable.lastAddedListener, listener);

      adapter.removeListener(listener);
      expect(listenable.removeListenerCount, 1);
      expect(listenable.lastRemovedListener, listener);
    });
  });
}
