import '../model/ui_models.dart';

typedef SendEventsCallback = void Function(List<UiEvent> events);
typedef DispatchEventCallback = void Function(UiEvent event);

class UiEventManager {
  UiEventManager({required this.callback});

  final SendEventsCallback callback;

  final Map<String, Map<String, UiEvent>> _coalescedEvents = {};

  void add(UiEvent event) {
    if (!event.isAction) {
      // Coalesce events that don't signal a terminating action. Only the last
      // value for each event type matters.
      _coalescedEvents[event.widgetId] ??= <String, UiEvent>{};
      _coalescedEvents[event.widgetId]![event.eventType] = event;
    } else {
      _send(event);
    }
  }

  void _send(UiEvent triggerAction) {
    final events = <UiEvent>[
      triggerAction,
      ..._coalescedEvents.values.expand((event) => event.values),
    ];
    _coalescedEvents.clear();
    if (events.isNotEmpty) {
      // Sort by timestamp to maintain order for non-coalesced events.
      events.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      callback(events);
    }
  }

  void dispose() {
    _coalescedEvents.clear();
  }
}
