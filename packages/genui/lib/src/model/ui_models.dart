// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

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
         if (surfaceId != null) surfaceIdKey: surfaceId,
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
  static const String catalogId = 'catalogId';
  static const String components = 'components';
  static const String theme = 'theme';
}

/// A data object that represents the entire UI definition.
///
/// This is the root object that defines a complete UI to be rendered.
class UiDefinition {
  /// The ID of the surface that this UI belongs to.
  final String surfaceId;

  /// The ID of the catalog to use for rendering this surface.
  final String? catalogId;

  /// A map of all widget definitions in the UI, keyed by their ID.
  Map<String, Component> get components => UnmodifiableMapView(_components);
  final Map<String, Component> _components;

  /// The theme for this surface.
  final JsonMap? theme;

  /// Creates a [UiDefinition].
  UiDefinition({
    required this.surfaceId,
    this.catalogId,
    Map<String, Component> components = const {},
    this.theme,
  }) : _components = components;

  /// Creates a [UiDefinition] from a JSON map.
  factory UiDefinition.fromJson(JsonMap json) {
    return UiDefinition(
      surfaceId: json[surfaceIdKey] as String,
      catalogId: json[_Json.catalogId] as String?,
      components:
          (json[_Json.components] as Map<String, Object?>?)?.map(
            (key, value) => MapEntry(key, Component.fromJson(value as JsonMap)),
          ) ??
          const {},
      theme: json[_Json.theme] as JsonMap?,
    );
  }

  /// Creates a copy of this [UiDefinition] with the given fields replaced.
  UiDefinition copyWith({
    String? catalogId,
    Map<String, Component>? components,
    JsonMap? theme,
  }) {
    return UiDefinition(
      surfaceId: surfaceId,
      catalogId: catalogId ?? this.catalogId,
      components: components ?? _components,
      theme: theme ?? this.theme,
    );
  }

  /// Converts this object to a JSON map.
  JsonMap toJson() {
    return {
      surfaceIdKey: surfaceId,
      if (catalogId != null) _Json.catalogId: catalogId,
      _Json.components: components.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      if (theme != null) _Json.theme: theme,
    };
  }

  /// Converts a UI definition into a blob of text.
  String asContextDescriptionText() {
    final String text = jsonEncode(this);
    return 'A user interface is shown with the following content:\n$text.';
  }

  /// Validates the UI definition against a schema.
  /// Throws [GenUiValidationException] if validation fails.
  void validate(Schema schema) {
    final String jsonOutput = schema.toJson();
    final schemaMap = jsonDecode(jsonOutput) as Map<String, dynamic>;

    List<Map<String, dynamic>> allowedSchemas = [];
    if (schemaMap.containsKey('oneOf')) {
      allowedSchemas = (schemaMap['oneOf'] as List)
          .cast<Map<String, dynamic>>();
    } else if (schemaMap.containsKey('properties') &&
        (schemaMap['properties'] as Map).containsKey('components')) {
      final componentsProp =
          (schemaMap['properties'] as Map)['components']
              as Map<String, dynamic>;
      if (componentsProp.containsKey('items')) {
        final items = componentsProp['items'] as Map<String, dynamic>;
        if (items.containsKey('oneOf')) {
          allowedSchemas = (items['oneOf'] as List)
              .cast<Map<String, dynamic>>();
        } else {
          allowedSchemas = [items];
        }
      }
    }

    if (allowedSchemas.isEmpty) {
      return;
    }

    for (final Component component in components.values) {
      var matched = false;
      List<String> errors = [];
      final JsonMap instanceJson = component.toJson();

      for (final s in allowedSchemas) {
        if (_schemaMatchesType(s, component.type)) {
          try {
            _validateInstance(instanceJson, s, '/components/${component.id}');
            matched = true;
            break;
          } catch (e) {
            errors.add(e.toString());
          }
        }
      }

      if (!matched) {
        if (errors.isNotEmpty) {
          throw GenUiValidationException(
            surfaceId: surfaceId,
            message:
                'Validation failed for component ${component.id} '
                '(${component.type}): ${errors.join("; ")}',
            path: '/components/${component.id}',
          );
        }
        throw GenUiValidationException(
          surfaceId: surfaceId,
          message: 'Unknown component type: ${component.type}',
          path: '/components/${component.id}',
        );
      }
    }
  }

  bool _schemaMatchesType(Map<String, dynamic> schema, String type) {
    if (schema.containsKey('properties')) {
      final props = schema['properties'] as Map;
      if (props.containsKey('component')) {
        final compProp = props['component'] as Map<String, dynamic>;
        if (compProp.containsKey('const') && compProp['const'] == type) {
          return true;
        }
        if (compProp.containsKey('enum') &&
            (compProp['enum'] as List).contains(type)) {
          return true;
        }
      }
    }
    return false;
  }

  void _validateInstance(
    Object? instance,
    Map<String, dynamic> schema,
    String path,
  ) {
    if (instance == null) {
      return;
    }

    if (schema.containsKey('const')) {
      final Object? constVal = schema['const'];
      if (instance != constVal) {
        throw GenUiValidationException(
          surfaceId: surfaceId,
          message: 'Value mismatch. Expected $constVal, got $instance',
          path: path,
        );
      }
    }

    if (schema.containsKey('enum')) {
      final enums = schema['enum'] as List;
      if (!enums.contains(instance)) {
        throw GenUiValidationException(
          surfaceId: surfaceId,
          message: 'Value not in enum: $instance',
          path: path,
        );
      }
    }

    if (schema.containsKey('required') && instance is Map) {
      final List<String> required = (schema['required'] as List).cast<String>();
      for (final key in required) {
        if (!instance.containsKey(key)) {
          throw GenUiValidationException(
            surfaceId: surfaceId,
            message: 'Missing required property: $key',
            path: path,
          );
        }
      }
    }

    if (schema.containsKey('properties') && instance is Map) {
      final props = schema['properties'] as Map<String, dynamic>;
      for (final MapEntry<String, dynamic> entry in props.entries) {
        final String key = entry.key;
        final propSchema = entry.value as Map<String, dynamic>;
        if (instance.containsKey(key)) {
          _validateInstance(instance[key], propSchema, '$path/$key');
        }
      }
    }

    if (schema.containsKey('items') && instance is List) {
      final itemsSchema = schema['items'] as Map<String, dynamic>;
      for (var i = 0; i < instance.length; i++) {
        _validateInstance(instance[i], itemsSchema, '$path/$i');
      }
    }

    if (schema.containsKey('oneOf')) {
      final List<Map<String, dynamic>> oneOfs = (schema['oneOf'] as List)
          .cast<Map<String, dynamic>>();
      var oneMatched = false;
      for (final s in oneOfs) {
        try {
          _validateInstance(instance, s, path);
          oneMatched = true;
          break;
        } catch (_) {}
      }
      if (!oneMatched) {
        throw GenUiValidationException(
          surfaceId: surfaceId,
          message: 'Value did not match any oneOf schema',
          path: path,
        );
      }
    }
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

/// Exception thrown when validation fails.
class GenUiValidationException implements Exception {
  /// The ID of the surface where the validation error occurred.
  final String surfaceId;

  /// A descriptive message for the validation error.
  final String message;

  /// The path in the data/component model where the error occurred.
  final String path;

  /// Creates a [GenUiValidationException].
  GenUiValidationException({
    required this.surfaceId,
    required this.message,
    this.path = '/',
  });

  @override
  String toString() => 'GenUiValidationException: $message (at $path)';
}
