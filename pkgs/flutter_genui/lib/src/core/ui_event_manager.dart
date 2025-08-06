import '../model/ui_models.dart';

typedef SendEventsCallback =
    void Function(String surfaceId, List<UiEvent> events);
typedef DispatchEventCallback = void Function(UiEvent event);

class UiEventManager {
  UiEventManager({required this.callback});

  final SendEventsCallback callback;

  final Map<String, Map<String, Map<String, UiEvent>>> _coalescedEvents = {};

  void add(UiEvent event) {
    if (!event.isAction) {
      // Coalesce events that don't signal a terminating action. Only the last
      // value for each event type matters.
      _coalescedEvents[event.surfaceId] ??= <String, Map<String, UiEvent>>{};
      _coalescedEvents[event.surfaceId]![event.widgetId] ??=
          <String, UiEvent>{};
      _coalescedEvents[event.surfaceId]![event.widgetId]![event.eventType] =
          event;
    } else {
      _send(event);
    }
  }

  void _send(UiEvent triggerAction) {
    // Send the events for the triggering event surface ID.
    final events = <UiEvent>[
      triggerAction,
      ..._coalescedEvents[triggerAction.surfaceId]?.values.expand(
            (event) => event.values,
          ) ??
          [],
    ];
    _coalescedEvents[triggerAction.surfaceId]?.clear();

    // Sort by timestamp to maintain order for non-coalesced events.
    events.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    callback(triggerAction.surfaceId, events);
  }

  void dispose() {
    _coalescedEvents.clear();
  }
}
