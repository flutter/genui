// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import '../primitives/simple_items.dart';
import 'a2ui_message.dart';

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
extension type UserActionEvent.fromMap(JsonMap _json) implements UiEvent {
  /// Creates a [UserActionEvent] from a set of properties.
  UserActionEvent({
    String? surfaceId,
    required String actionName,
    required String sourceComponentId,
    DateTime? timestamp,
    JsonMap? context,
  }) : _json = {
         if (surfaceId != null) 'surfaceId': surfaceId,
         'actionName': actionName,
         'sourceComponentId': sourceComponentId,
         'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
         'isAction': true,
         'context': context ?? {},
       };

  String get actionName => _json['actionName'] as String;
  String get sourceComponentId => _json['sourceComponentId'] as String;
  JsonMap get context => _json['context'] as JsonMap;
}

/// A data object that represents the entire UI definition.
///
/// This is the root object that defines a complete UI to be rendered.
class UiDefinition {
  /// The ID of the surface that this UI belongs to.
  final String surfaceId;

  /// The ID of the root widget in the UI tree.
  final String? rootComponentId;

  /// A map of all widget definitions in the UI, keyed by their ID.
  final Map<String, Component> components;

  /// (Future) The URI of the catalog used for this surface.
  final Uri? catalogUri;

  /// (Future) The styles for this surface.
  final JsonMap? styles;

  /// Creates a [UiDefinition].
  UiDefinition({
    required this.surfaceId,
    this.rootComponentId,
    this.components = const {},
    this.catalogUri,
    this.styles,
  });

  /// Creates a copy of this [UiDefinition] with the given fields replaced.
  UiDefinition copyWith({
    String? rootComponentId,
    Map<String, Component>? components,
    Uri? catalogUri,
    JsonMap? styles,
  }) {
    return UiDefinition(
      surfaceId: surfaceId,
      rootComponentId: rootComponentId ?? this.rootComponentId,
      components: components ?? this.components,
      catalogUri: catalogUri ?? this.catalogUri,
      styles: styles ?? this.styles,
    );
  }

  /// Converts this object to a JSON map.
  JsonMap toJson() {
    return {
      'surfaceId': surfaceId,
      'rootComponentId': rootComponentId,
      'components': components.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    };
  }

  /// Converts a UI definition into a blob of text
  String asContextDescriptionText() {
    final text = jsonEncode(this);
    return 'A user interface is shown with the following content:\n$text.';
  }
}
