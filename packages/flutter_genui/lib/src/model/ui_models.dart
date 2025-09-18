// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import '../primitives/simple_items.dart';

/// A callback that is called when events are sent.
typedef SendEventsCallback =
    void Function(String surfaceId, List<UiEvent> events);

/// A callback that is called when an event is dispatched.
typedef DispatchEventCallback = void Function(UiEvent event);

/// A data object that represents a user interaction event in the UI.
///
/// This is used to send information from the app to the AI about user
/// actions, such as tapping a button or entering text.
extension type UiEvent.fromMap(JsonMap _json) {
  /// The ID of the surface that this event originated from.
  String get surfaceId => _json['surfaceId'] as String;

  /// The ID of the widget that triggered the event.
  String get widgetId => _json['widgetId'] as String;

  /// The type of event that was triggered (e.g., 'onChanged', 'onTap').
  String get eventType => _json['eventType'] as String;

  /// Whether this event should trigger an event.
  ///
  /// The event can be a submission to the AI or
  /// a change in the UI state that should be handled by
  /// host of the surface.
  bool get isAction => _json['isAction'] as bool;

  /// The value associated with the event, if any (e.g., the text in a
  /// `TextField`, or the value of a `Checkbox`).
  Object? get value => _json['value'];

  /// The timestamp of when the event occurred.
  DateTime get timestamp => DateTime.parse(_json['timestamp'] as String);

  /// Converts this event to a map, suitable for JSON serialization.
  JsonMap toMap() => _json;
}

/// A UI event that represents a user action.
///
/// This is used for events that should trigger a submission to the AI, such as
/// tapping a button.
extension type UiActionEvent.fromMap(JsonMap _json) implements UiEvent {
  /// Creates a [UiEvent] from a set of properties.
  UiActionEvent({
    String? surfaceId,
    required String widgetId,
    required String eventType,
    DateTime? timestamp,
    Object? value,
  }) : _json = {
         if (surfaceId != null) 'surfaceId': surfaceId,
         'widgetId': widgetId,
         'eventType': eventType,
         'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
         'isAction': true,
         if (value != null) 'value': value,
       };
}

/// A data object that represents the entire UI definition.
///
/// This is the root object that defines a complete UI to be rendered.
extension type UiDefinition.fromMap(JsonMap _json) {
  /// The ID of the surface that this UI belongs to.
  String get surfaceId => _json['surfaceId'] as String;

  /// The ID of the root widget in the UI tree.
  String get root => _json['root'] as String;

  /// The original list of widget definitions.
  List<Object?> get widgetList => _json['widgets'] as List<Object?>;

  JsonMap toMap() => _json;

  /// A map of all widget definitions in the UI, keyed by their ID.
  JsonMap get widgets {
    final widgetById = <String, Object?>{};

    for (final widget in (_json['widgets'] as List<Object?>)) {
      var typedWidget = widget as JsonMap;
      widgetById[typedWidget['id'] as String] = typedWidget;
    }

    return widgetById;
  }

  /// Converts a UI definition into a blob of text
  String asContextDescriptionText() {
    final text = jsonEncode(this);
    return 'A user interface is shown with the following content:\n$text.';
  }
}
