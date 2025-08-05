// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../model/ui_models.dart';

typedef SendEventsCallback = void Function(List<UiEvent> events);

/// Manages UI events, coalescing state changes and batching them with action
/// events.
class UiEventManager {
  /// Creates a [UiEventManager].
  ///
  /// The [callback] is invoked with a list of events when an action event
  /// occurs.
  UiEventManager({required this.callback});

  /// The callback to be invoked with a list of events.
  final SendEventsCallback callback;

  final Map<String, Map<String, UiEvent>> _coalescedEvents = {};

  /// Adds a [UiEvent] to the manager.
  ///
  /// If the event is a [UiChangeEvent], it is stored and coalesced with
  /// previous change events for the same widget.
  ///
  /// If the event is a [UiActionEvent], all pending change events are
  /// dispatched along with the action event via the [callback].
  void add(UiEvent event) {
    if (event is UiChangeEvent) {
      _coalescedEvents[event.widgetId] ??= <String, UiEvent>{};
      _coalescedEvents[event.widgetId]![event.eventType] = event;
    } else {
      _send(event);
    }
  }

  void _send(UiEvent triggerEvent) {
    final events = <UiEvent>[
      triggerEvent,
      ..._coalescedEvents.values.expand((eventTypeMap) => eventTypeMap.values),
    ];
    _coalescedEvents.clear();
    if (events.isNotEmpty) {
      // Sort by timestamp to maintain order for non-coalesced events.
      events.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      callback(events);
    }
  }
}
