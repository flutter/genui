import 'dart:async';

import 'package:flutter/foundation.dart';
import 'ui_models.dart';

typedef DebounceCallback = void Function(List<UiEvent> events);

class EventDebouncer {
  EventDebouncer({
    required this.callback,
    this.delay = const Duration(seconds: 2),
  });

  @visibleForTesting
  EventDebouncer.test({
    required this.callback,
  }) : delay = Duration.zero;

  final DebounceCallback callback;
  final Duration delay;

  Timer? _timer;
  final List<UiEvent> _eventQueue = [];
  final Map<String, UiEvent> _coalescedEvents = {};

  void add(UiEvent event) {
    _timer?.cancel();

    // Coalesce events that happen rapidly and only the last value matters.
    if (event.eventType == 'onChanged') {
      _coalescedEvents[event.widgetId] = event;
    } else {
      // For other events (like onTap), we want to keep all of them.
      _eventQueue.add(event);
    }

    _timer = Timer(delay, _fire);
  }

  void _fire() {
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
    _timer?.cancel();
  }
}
