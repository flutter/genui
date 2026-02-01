// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:collection/collection.dart';

import '../model/tools.dart';
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
  String get surfaceId => _json[surfaceIdKey] as String;

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
    required String name,
    required String sourceComponentId,
    DateTime? timestamp,
    JsonMap? context,
  }) : _json = {
         surfaceIdKey: ?surfaceId,
         'name': name,
         'sourceComponentId': sourceComponentId,
         'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
         'isAction': true,
         'context': context ?? {},
       };

  String get name => _json['name'] as String;
  String get sourceComponentId => _json['sourceComponentId'] as String;
  JsonMap get context => _json['context'] as JsonMap;
}

final class _Json {
  static const String rootComponentId = 'rootComponentId';
  static const String catalogId = 'catalogId';
  static const String components = 'components';
  static const String styles = 'styles';
}

/// A data object that represents the entire UI definition.
///
/// This is the root object that defines a complete UI to be rendered.
class UiDefinition {
  /// The ID of the surface that this UI belongs to.
  final String surfaceId;

  /// The ID of the root widget in the UI tree.
  final String? rootComponentId;

  /// The ID of the catalog to use for rendering this surface.
  final String? catalogId;

  /// A map of all widget definitions in the UI, keyed by their ID.
  Map<String, Component> get components => UnmodifiableMapView(_components);
  final Map<String, Component> _components;

  /// (Future) The styles for this surface.
  final JsonMap? styles;

  /// Creates a [UiDefinition].
  UiDefinition({
    required this.surfaceId,
    this.rootComponentId,
    this.catalogId,
    Map<String, Component> components = const {},
    this.styles,
  }) : _components = components;

  /// Creates a [UiDefinition] from a JSON map.
  factory UiDefinition.fromJson(JsonMap json) {
    return UiDefinition(
      surfaceId: json[surfaceIdKey] as String,
      rootComponentId: json[_Json.rootComponentId] as String?,
      catalogId: json[_Json.catalogId] as String?,
      components:
          (json[_Json.components] as Map<String, Object?>?)?.map(
            (key, value) => MapEntry(key, Component.fromJson(value as JsonMap)),
          ) ??
          const {},
      styles: json[_Json.styles] as JsonMap?,
    );
  }

  /// Creates a copy of this [UiDefinition] with the given fields replaced.
  UiDefinition copyWith({
    String? rootComponentId,
    String? catalogId,
    Map<String, Component>? components,
    JsonMap? styles,
  }) {
    return UiDefinition(
      surfaceId: surfaceId,
      rootComponentId: rootComponentId ?? this.rootComponentId,
      catalogId: catalogId ?? this.catalogId,
      components: components ?? _components,
      styles: styles ?? this.styles,
    );
  }

  /// Converts this object to a JSON map.
  JsonMap toJson() {
    return {
      surfaceIdKey: surfaceId,
      if (rootComponentId != null) _Json.rootComponentId: rootComponentId,
      if (catalogId != null) _Json.catalogId: catalogId,
      _Json.components: components.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      if (styles != null) _Json.styles: styles,
    };
  }

  /// Converts a UI definition into a blob of text
  String asContextDescriptionText() {
    final String text = jsonEncode(this);
    return 'A user interface is shown with the following content:\n$text.';
  }
}

/// A component in the UI.
final class Component {
  /// Creates a [Component].
  const Component({
    required this.id,
    required this.componentProperties,
    this.weight,
  });

  /// Creates a [Component] from a JSON map.
  factory Component.fromJson(JsonMap json) {
    if (json['component'] == null) {
      throw ArgumentError('Component.fromJson: component property is null');
    }
    return Component(
      id: json['id'] as String,
      componentProperties: json['component'] as JsonMap,
      weight: json['weight'] as int?,
    );
  }

  /// The unique ID of the component.
  final String id;

  /// The properties of the component.
  final JsonMap componentProperties;

  /// The weight of the component, used for layout in Row/Column.
  final int? weight;

  /// Converts this object to a JSON map.
  JsonMap toJson() {
    return {
      'id': id,
      'component': componentProperties,
      if (weight != null) 'weight': weight,
    };
  }

  /// The type of the component.
  String get type => componentProperties.keys.first;

  @override
  bool operator ==(Object other) =>
      other is Component &&
      id == other.id &&
      weight == other.weight &&
      const DeepCollectionEquality().equals(
        componentProperties,
        other.componentProperties,
      );

  @override
  int get hashCode => Object.hash(
    id,
    weight,
    const DeepCollectionEquality().hash(componentProperties),
  );
}
