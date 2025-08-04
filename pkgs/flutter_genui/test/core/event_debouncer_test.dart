// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_genui/src/core/event_debouncer.dart';
import 'package:flutter_genui/src/model/ui_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EventDebouncer', () {
    test('callback is called after delay', () async {
      final completer = Completer<List<UiEvent>>();
      final debouncer = EventDebouncer(
        callback: completer.complete,
        delay: const Duration(milliseconds: 10),
      );

      debouncer.add(
        UiEvent(
          surfaceId: 's1',
          widgetId: 'w1',
          eventType: 'onTap',
          timestamp: DateTime.now(),
        ),
      );

      final events = await completer.future;
      expect(events.length, 1);
      expect(events.first.widgetId, 'w1');
      debouncer.dispose();
    });

    test('onChanged events are coalesced', () async {
      final completer = Completer<List<UiEvent>>();
      final debouncer = EventDebouncer(
        callback: completer.complete,
        delay: const Duration(milliseconds: 10),
      );

      debouncer.add(
        UiEvent(
          surfaceId: 's1',
          widgetId: 'w1',
          eventType: 'onChanged',
          value: 'first',
          timestamp: DateTime.now(),
        ),
      );
      debouncer.add(
        UiEvent(
          surfaceId: 's1',
          widgetId: 'w1',
          eventType: 'onChanged',
          value: 'last',
          timestamp: DateTime.now().add(const Duration(milliseconds: 1)),
        ),
      );

      final events = await completer.future;
      expect(events.length, 1);
      expect(events.first.widgetId, 'w1');
      expect(events.first.value, 'last');
      debouncer.dispose();
    });

    test('different event types are not coalesced', () async {
      final completer = Completer<List<UiEvent>>();
      final debouncer = EventDebouncer(
        callback: completer.complete,
        delay: const Duration(milliseconds: 10),
      );

      debouncer.add(
        UiEvent(
          surfaceId: 's1',
          widgetId: 'w1',
          eventType: 'onTap',
          timestamp: DateTime.now(),
        ),
      );
      debouncer.add(
        UiEvent(
          surfaceId: 's1',
          widgetId: 'w2',
          eventType: 'onSubmitted',
          timestamp: DateTime.now().add(const Duration(milliseconds: 1)),
        ),
      );

      final events = await completer.future;
      expect(events.length, 2);
      debouncer.dispose();
    });

    test('dispose cancels timer', () async {
      var callbackCalled = false;
      final debouncer = EventDebouncer(
        callback: (events) => callbackCalled = true,
        delay: const Duration(milliseconds: 10),
      );

      debouncer.add(
        UiEvent(
          surfaceId: 's1',
          widgetId: 'w1',
          eventType: 'onTap',
          timestamp: DateTime.now(),
        ),
      );
      debouncer.dispose();

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(callbackCalled, isFalse);
    });

    test('events are sorted by timestamp', () async {
      final completer = Completer<List<UiEvent>>();
      final debouncer = EventDebouncer(
        callback: completer.complete,
        delay: const Duration(milliseconds: 10),
      );

      final time1 = DateTime.now();
      final time2 = time1.add(const Duration(milliseconds: 1));
      final time3 = time2.add(const Duration(milliseconds: 1));

      debouncer.add(
        UiEvent(
          surfaceId: 's1',
          widgetId: 'w2',
          eventType: 'onTap',
          timestamp: time2,
        ),
      );
      debouncer.add(
        UiEvent(
          surfaceId: 's1',
          widgetId: 'w1',
          eventType: 'onTap',
          timestamp: time1,
        ),
      );
      debouncer.add(
        UiEvent(
          surfaceId: 's1',
          widgetId: 'w3',
          eventType: 'onChanged',
          timestamp: time3,
        ),
      );

      final events = await completer.future;
      expect(events.length, 3);
      expect(events[0].widgetId, 'w1');
      expect(events[1].widgetId, 'w2');
      expect(events[2].widgetId, 'w3');
      debouncer.dispose();
    });
  });
}
