import '../model/ui_models.dart';

typedef SendEventsCallback = void Function(List<UiEvent> events);

class UiEventManager {
  UiEventManager({required this.callback});

  final SendEventsCallback callback;

  final List<UiEvent> _eventQueue = [];
  final Map<String, UiEvent> _coalescedEvents = {};

  void add(UiEvent event) {
    // Coalesce events that happen rapidly and only the last value matters.
    if (event.eventType == 'onChanged') {
      _coalescedEvents[event.widgetId] = event;
    } else {
      // For other events (like onTap), we want to keep all of them.
      _eventQueue.add(event);
    }

    if (event.isSubmit) {
      _send();
    }
  }

  void _send() {
    final events = <UiEvent>[..._eventQueue, ..._coalescedEvents.values];
    _eventQueue.clear();
    _coalescedEvents.clear();
    if (events.isNotEmpty) {
      // Sort by timestamp to maintain order for non-coalesced events.
      events.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      callback(events);
    }
  }

  void dispose() {
    _eventQueue.clear();
    _coalescedEvents.clear();
  }
}
