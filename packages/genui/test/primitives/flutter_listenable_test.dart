// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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

class TestGenUiValueListenable<T> extends TestGenUiListenable
    implements GenUiValueListenable<T> {
  TestGenUiValueListenable(this.value);

  @override
  T value;
}

void main() {
  group('FlutterListenable', () {
    test('adapter registers and unregisters listeners correctly', () {
      final listenable = TestGenUiListenable();
      final Listenable adapter = listenable.listenable();

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

    test('valueListenable adapter works correctly', () {
      final valueListenable = TestGenUiValueListenable<int>(42);
      final ValueListenable<int> adapter = valueListenable.valueListenable();

      expect(adapter, isA<ValueListenable<int>>());
      expect(adapter, isA<FlutterValueListenableAdapter<int>>());

      expect(adapter.value, 42);

      void listener() {}

      adapter.addListener(listener);
      expect(valueListenable.addListenerCount, 1);
      expect(valueListenable.lastAddedListener, listener);

      adapter.removeListener(listener);
      expect(valueListenable.removeListenerCount, 1);
      expect(valueListenable.lastRemovedListener, listener);
    });
  });
}
