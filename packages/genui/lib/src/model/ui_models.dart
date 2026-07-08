// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:a2ui_core/a2ui_core.dart' as core;
import 'package:collection/collection.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:meta/meta.dart' show internal;

import '../primitives/constants.dart';
import '../primitives/simple_items.dart';
import 'schema_validation.dart' as schema_validation;

/// A callback that is called when events are sent.
typedef SendEventsCallback =
    void Function(String surfaceId, List<UiEvent> events);

/// A callback that is called when an event is dispatched.
typedef DispatchEventCallback = void Function(UiEvent event);

/// A data object that represents a user interaction event in the UI.
///
/// Used to send information from the app to the AI about user actions,
/// such as tapping a button or entering text.
extension type UiEvent.fromMap(JsonMap _json) {
  /// The ID of the surface that this event originated from.
  String get surfaceId => _json[surfaceIdKey] as String;

  /// The ID of the widget that triggered the event.
  String get widgetId => _json['widgetId'] as String;

  /// The type of event that was triggered (e.g., 'onChanged', 'onTap').
  String get eventType => _json['eventType'] as String;

  /// The value associated with the event, if any.
  Object? get value => _json['value'];

  /// The timestamp of when the event occurred.
  DateTime get timestamp => DateTime.parse(_json['timestamp'] as String);

  /// Whether this is a [UserActionEvent]. Extension types are erased to their
  /// representation at runtime, so `event is UserActionEvent` is always true
  /// for any [UiEvent]; the action's `name` key is the real discriminator.
  bool get isUserAction => _json.containsKey('name');

  /// Converts this event to a map, suitable for JSON serialization.
  JsonMap toMap() => _json;
}

/// A UI event that represents a user action; triggers a submission to the AI.
extension type UserActionEvent.fromMap(JsonMap _json) implements UiEvent {
  /// Creates a [UserActionEvent] from a set of properties.
  UserActionEvent({
    String? surfaceId,
    required String name,
    required String sourceComponentId,
    DateTime? timestamp,
    JsonMap? context,
    bool wantResponse = false,
    String? actionId,
  }) : _json = {
         surfaceIdKey: ?surfaceId,
         'name': name,
         'sourceComponentId': sourceComponentId,
         'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
         'context': context ?? {},
         if (wantResponse) 'wantResponse': wantResponse,
         'actionId': ?actionId,
       };

  /// The name of the action.
  String get name => _json['name'] as String;

  /// The ID of the component that triggered the action.
  String get sourceComponentId => _json['sourceComponentId'] as String;

  /// Context associated with the action.
  JsonMap get context => _json['context'] as JsonMap;

  /// Whether the client expects an `actionResponse` from the server.
  bool get wantResponse => _json['wantResponse'] as bool? ?? false;

  /// Unique ID for this action call, set when [wantResponse] is true.
  String? get actionId => _json['actionId'] as String?;
}

final class _Json {
  static const String catalogId = 'catalogId';
  static const String components = 'components';
  static const String surfaceProperties = 'surfaceProperties';
}

/// A data object that represents the entire UI definition.
///
/// This is an immutable snapshot; the live, mutable state is owned by
/// `a2ui_core.SurfaceModel`.
class SurfaceDefinition {
  /// Creates a [SurfaceDefinition].
  SurfaceDefinition({
    required this.surfaceId,
    this.catalogId = basicCatalogId,
    Map<String, Component> components = const {},
    this.surfaceProperties,
  }) : _components = components;

  /// Creates a [SurfaceDefinition] from a JSON map.
  factory SurfaceDefinition.fromJson(JsonMap json) {
    return SurfaceDefinition(
      surfaceId: json[surfaceIdKey] as String,
      catalogId: json[_Json.catalogId] as String? ?? basicCatalogId,
      components:
          (json[_Json.components] as Map<String, Object?>?)?.map(
            (key, value) => MapEntry(key, Component.fromJson(value as JsonMap)),
          ) ??
          const {},
      surfaceProperties: json[_Json.surfaceProperties] as JsonMap?,
    );
  }

  /// Creates a snapshot from a live core surface model.
  factory SurfaceDefinition.fromCore(core.SurfaceModel surface) {
    return SurfaceDefinition(
      surfaceId: surface.id,
      catalogId: surface.catalog.id,
      components: {
        for (final core.ComponentModel component in surface.componentsModel.all)
          component.id: Component.fromCore(component),
      },
      surfaceProperties: surface.surfaceProperties.isEmpty
          ? null
          : JsonMap.from(surface.surfaceProperties),
    );
  }

  /// The ID of the surface that this UI belongs to.
  final String surfaceId;

  /// The ID of the catalog to use for rendering this surface.
  final String catalogId;

  /// A map of all widget definitions in the UI, keyed by their ID.
  Map<String, Component> get components => UnmodifiableMapView(_components);
  final Map<String, Component> _components;

  /// The surface properties for this surface (e.g. agentDisplayName).
  final JsonMap? surfaceProperties;

  /// Creates a copy of this [SurfaceDefinition] with the given fields replaced.
  SurfaceDefinition copyWith({
    String? catalogId,
    Map<String, Component>? components,
    JsonMap? surfaceProperties,
  }) {
    return SurfaceDefinition(
      surfaceId: surfaceId,
      catalogId: catalogId ?? this.catalogId,
      components: components ?? _components,
      surfaceProperties: surfaceProperties ?? this.surfaceProperties,
    );
  }

  /// Converts this object to a JSON map.
  JsonMap toJson() {
    return {
      surfaceIdKey: surfaceId,
      _Json.catalogId: catalogId,
      _Json.components: components.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      _Json.surfaceProperties: ?surfaceProperties,
    };
  }

  /// Converts a UI definition into a blob of text.
  String asContextDescriptionText() {
    final String text = jsonEncode(this);
    return 'A user interface is shown with the following content:\n$text.';
  }

  /// Validates the UI definition against a schema.
  void validate(Schema schema) {
    schema_validation.validateComponents(
      surfaceId: surfaceId,
      components: components.values.map(
        (c) => (id: c.id, type: c.type, json: c.toJson()),
      ),
      schema: schema,
    );
  }
}

/// A component in the UI.
final class Component {
  /// Creates a [Component].
  const Component({
    required this.id,
    required this.type,
    required this.properties,
  });

  /// Creates a [Component] from a JSON map.
  factory Component.fromJson(JsonMap json) {
    if (json['component'] == null) {
      throw ArgumentError('Component.fromJson: component property is null');
    }
    final rawType = json['component'] as String;
    final id = json['id'] as String;

    final properties = Map<String, Object?>.from(json);
    properties.remove('id');
    properties.remove('component');

    return Component(id: id, type: rawType, properties: properties);
  }

  /// Creates a snapshot from a live core component model.
  factory Component.fromCore(core.ComponentModel component) {
    return Component(
      id: component.id,
      type: component.type,
      properties: JsonMap.from(component.properties),
    );
  }

  /// The unique ID of the component.
  final String id;

  /// The type of the component (e.g. 'Text', 'Button').
  final String type;

  /// The properties of the component.
  final JsonMap properties;

  /// Converts this object to a JSON map.
  JsonMap toJson() {
    return {'id': id, 'component': type, ...properties};
  }

  @override
  bool operator ==(Object other) =>
      other is Component &&
      id == other.id &&
      type == other.type &&
      const DeepCollectionEquality().equals(properties, other.properties);

  @override
  int get hashCode =>
      Object.hash(id, type, const DeepCollectionEquality().hash(properties));
}

/// Surface lifecycle events emitted by `SurfaceController.surfaceUpdates`.
sealed class SurfaceUpdate {
  const SurfaceUpdate(this.surfaceId);
  final String surfaceId;
}

/// Fired when a new surface is created.
final class SurfaceAdded extends SurfaceUpdate {
  /// Constructs from a [SurfaceDefinition]. `SurfaceController` uses
  /// [SurfaceAdded.fromCore] internally.
  const SurfaceAdded(super.surfaceId, this.definition);

  /// Internal: snapshots the definition from a live core surface.
  @internal
  SurfaceAdded.fromCore(super.surfaceId, core.SurfaceModel coreSurface)
    : definition = SurfaceDefinition.fromCore(coreSurface);

  /// Snapshot definition for this surface.
  final SurfaceDefinition definition;
}

/// Fired when an existing surface's component set is modified.
final class ComponentsUpdated extends SurfaceUpdate {
  /// Constructs from a [SurfaceDefinition]. `SurfaceController` uses
  /// [ComponentsUpdated.fromCore] internally.
  const ComponentsUpdated(super.surfaceId, this.definition);

  /// Internal: snapshots the definition from a live core surface.
  @internal
  ComponentsUpdated.fromCore(super.surfaceId, core.SurfaceModel coreSurface)
    : definition = SurfaceDefinition.fromCore(coreSurface);

  /// Snapshot definition for this surface.
  final SurfaceDefinition definition;
}

/// Fired when a surface is deleted.
final class SurfaceRemoved extends SurfaceUpdate {
  const SurfaceRemoved(super.surfaceId);
}
