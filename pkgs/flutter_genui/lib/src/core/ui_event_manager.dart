// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../model/ui_models.dart';

/// A callback that is called when events are sent.
typedef SendEventsCallback =
    void Function(String surfaceId, List<UiEvent> events);

/// A callback that is called when an event is dispatched.
typedef DispatchEventCallback = void Function(UiEvent event);

/// A class that manages UI events.
///
/// This class is responsible for coalescing UI events and sending them to the
/// AI client when an action is triggered.
class UiEventManager {
  /// Creates a new [UiEventManager].
  UiEventManager({required this.callback});

  /// The callback to call when events are sent.
  final SendEventsCallback callback;

  final Map<String, Map<String, Map<String, UiEvent>>> _coalescedEvents = {};

  /// Adds a UI event to the manager.
  ///
  /// If the event is an action, all coalesced events for the same surface are
  /// sent to the AI client. Otherwise, the event is coalesced with other
  /// events for the same widget and event type.
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

  /// Disposes of the resources used by the manager.
  void dispose() {
    _coalescedEvents.clear();
  }
}
