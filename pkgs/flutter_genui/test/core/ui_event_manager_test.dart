import 'package:flutter_genui/src/core/ui_event_manager.dart';
import 'package:flutter_genui/src/model/ui_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UiEventManager', () {
    test('accumulates state change events and sends on action', () {
      final sentEvents = <UiEvent>[];
      final manager = UiEventManager(callback: sentEvents.addAll);

      final event1 = UiChangeEvent(
        surfaceId: 's1',
        widgetId: 'w1',
        eventType: 'onChanged',
        timestamp: DateTime(2025),
        value: 'a',
      );
      final event2 = UiActionEvent(
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

      expect(sentEvents, hasLength(2));
      expect(sentEvents[0], equals(event1));
      expect(sentEvents[1], equals(event2));

      sentEvents.clear();

      manager.add(submitEvent);

      expect(sentEvents, hasLength(2));
      expect(sentEvents[0], equals(event3));
      expect(sentEvents[1], equals(submitEvent));
    });

    test('coalesces state change events', () {
      final sentEvents = <UiEvent>[];
      final manager = UiEventManager(callback: sentEvents.addAll);

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
