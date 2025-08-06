import 'package:flutter_genui/src/core/ui_event_manager.dart';
import 'package:flutter_genui/src/model/ui_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UiEventManager', () {
    test('accumulates non-submit events and sends on submit', () {
      final sentEvents = <UiEvent>[];
      final manager = UiEventManager(
        callback: (_, events) => sentEvents.addAll(events),
      );

      final event1 = UiChangeEvent(
        surfaceId: 's1',
        widgetId: 'w1',
        eventType: 'onChanged',
        timestamp: DateTime(2025),
        value: 'a',
      );
      final event2 = UiChangeEvent(
        surfaceId: 's1',
        widgetId: 'w2',
        eventType: 'onTap',
        timestamp: DateTime(2025, 1, 1, 0, 0, 1),
        value: null,
      );
      final event3 = UiChangeEvent(
        surfaceId: 's1',
        widgetId: 'w1',
        eventType: 'onChanged',
        timestamp: DateTime(2025, 1, 1, 0, 0, 2),
        value: 'b',
      );
      final submitEvent = UiActionEvent(
        surfaceId: 's1',
        widgetId: 'w3',
        eventType: 'onTap',
        timestamp: DateTime(2025, 1, 1, 0, 0, 3),
        value: null,
      );

      manager.add(event1);
      manager.add(event2);
      manager.add(event3);

      expect(sentEvents, isEmpty);

      manager.add(submitEvent);

      expect(sentEvents, hasLength(3));
      expect(sentEvents[0], equals(event2));
      expect(sentEvents[1], equals(event3));
      expect(sentEvents[2], equals(submitEvent));
    });

    test('coalesces onChanged events', () {
      final sentEvents = <UiEvent>[];
      final manager = UiEventManager(
        callback: (_, events) => sentEvents.addAll(events),
      );

      final event1 = UiChangeEvent(
        surfaceId: 's1',
        widgetId: 'w1',
        eventType: 'onChanged',
        timestamp: DateTime(2025),
        value: 'a',
      );
      final event2 = UiChangeEvent(
        surfaceId: 's1',
        widgetId: 'w1',
        eventType: 'onChanged',
        timestamp: DateTime(2025, 1, 1, 0, 0, 1),
        value: 'b',
      );
      final submitEvent = UiActionEvent(
        surfaceId: 's1',
        widgetId: 'w2',
        eventType: 'onTap',
        timestamp: DateTime(2025, 1, 1, 0, 0, 2),
        value: null,
      );

      manager.add(event1);
      manager.add(event2);
      manager.add(submitEvent);

      expect(sentEvents, hasLength(2));
      expect(sentEvents[0], equals(event2));
      expect(sentEvents[1], equals(submitEvent));
    });
  });
}
