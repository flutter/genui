// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:json_schema_builder/json_schema_builder.dart' show ObjectSchema;

import '../constants.dart';

/// Extension to provide JSON stringification for map-based objects.
extension JsonEncodeMap on Map<String, Object?> {
  /// Converts this map object to a JSON string.
  ///
  /// - [indent]: If non-empty, the JSON output will be pretty-printed with
  ///   the given indent.
  String toJsonString({String indent = ''}) {
    if (indent.isNotEmpty) {
      return JsonEncoder.withIndent(indent).convert(this);
    }
    return const JsonEncoder().convert(this);
  }
}

/// A base extension type for FCP models that are represented as JSON objects.
extension type JsonObjectBase(Map<String, Object?> _json) {
  /// Returns the underlying JSON map.
  Map<String, Object?> toJson() => _json;
}

// -----------------------------------------------------------------------------
// Catalog-related Models
// -----------------------------------------------------------------------------

/// A type-safe wrapper for the `WidgetCatalog` JSON object.
///
/// The catalog is a client-defined document that specifies which widgets,
/// properties, events, and data structures the application is capable of
/// handling. It serves as a strict contract between the client and the server.
extension type WidgetCatalog.fromMap(Map<String, Object?> _json)
    implements JsonObjectBase {
  /// Creates a new [WidgetCatalog] from a map of [items] and [dataTypes].
  ///
  /// The [catalogVersion] defaults to [fcpVersion].
  factory WidgetCatalog({
    String catalogVersion = fcpVersion,
    required Map<String, Object?> dataTypes,
    required Map<String, WidgetDefinition?> items,
  }) => WidgetCatalog.fromMap({
    'catalogVersion': catalogVersion,
    'dataTypes': dataTypes,
    'items': items,
  });

  /// The version of the catalog file itself.
  String get catalogVersion => _json['catalogVersion'] as String;

  /// A map of custom data type names to their JSON Schema definitions.
  Map<String, Object?> get dataTypes =>
      _json['dataTypes'] as Map<String, Object?>;

  /// A map of widget type names to their definitions.
  Map<String, WidgetDefinition?> get items =>
      (_json['items'] as Map).cast<String, WidgetDefinition?>();
}

/// A type-safe wrapper for a `WidgetDefinition` JSON object.
///
/// This object describes a single renderable widget type, including its
/// supported properties and the events it can emit.
extension type WidgetDefinition.fromMap(Map<String, Object?> _json)
    implements JsonObjectBase {
  /// Creates a new [WidgetDefinition] from a [properties] schema and an
  /// optional [events] schema.
  factory WidgetDefinition({
    required ObjectSchema properties,
    ObjectSchema? events,
  }) => WidgetDefinition.fromMap({
    'properties': properties.value,
    if (events != null) 'events': events.value,
  });

  /// A JSON Schema object that defines the supported attributes for the widget.
  ObjectSchema get properties {
    final props = _json['properties'] as Map<String, Object?>?;
    if (props == null) {
      return ObjectSchema(properties: {});
    }
    return ObjectSchema.fromMap(props);
  }

  /// A map of event names to their JSON Schema definitions.
  ObjectSchema? get events {
    final events = _json['events'] as Map<String, Object?>?;
    return events == null ? null : ObjectSchema.fromMap(events);
  }
}

// -----------------------------------------------------------------------------
// UI Packet & Layout Models
// -----------------------------------------------------------------------------

/// A type-safe wrapper for a `DynamicUIPacket` JSON object.
///
/// This is the atomic and self-contained description of a UI view at a
/// specific moment, containing the layout, state, and metadata.
extension type DynamicUIPacket.fromMap(Map<String, Object?> _json)
    implements JsonObjectBase {
  /// Creates a new [DynamicUIPacket] from a [layout] and [state].
  ///
  /// The [formatVersion] defaults to [fcpVersion]. The [metadata] is optional.
  factory DynamicUIPacket({
    String formatVersion = fcpVersion,
    required Layout layout,
    required Map<String, Object?> state,
    Map<String, Object?>? metadata,
  }) => DynamicUIPacket.fromMap({
    'formatVersion': formatVersion,
    'layout': layout.toJson(),
    'state': state,
    if (metadata != null) 'metadata': metadata,
  });

  /// The version of the FCP specification.
  String get formatVersion => _json['formatVersion'] as String;

  /// The complete, non-recursive widget tree definition.
  Layout get layout =>
      Layout.fromMap(_json['layout'] as Map<String, Object?>? ?? {});

  /// The initial state data for the widgets defined in the layout.
  Map<String, Object?> get state =>
      _json['state'] as Map<String, Object?>? ?? {};

  /// An optional object for server-side information.
  Map<String, Object?>? get metadata =>
      _json['metadata'] as Map<String, Object?>?;
}

/// A type-safe wrapper for a `Layout` JSON object.
///
/// The layout defines the UI structure using a flat adjacency list model,
/// where parent-child relationships are established through ID references.
extension type Layout.fromMap(Map<String, Object?> _json)
    implements JsonObjectBase {
  /// Creates a new [Layout] from a [root] node ID and a list of [nodes].
  factory Layout({required String root, required List<LayoutNode> nodes}) =>
      Layout.fromMap({
        'root': root,
        'nodes': nodes.map((e) => e.toJson()).toList(),
      });

  /// The ID of the root layout node.
  String get root => _json['root'] as String;

  /// A flat list of all the layout nodes in the UI.
  List<LayoutNode> get nodes {
    final nodeList = _json['nodes'] as List<Object?>? ?? [];
    return nodeList
        .cast<Map<String, Object?>>()
        .map(LayoutNode.fromMap)
        .toList();
  }
}

/// A type-safe wrapper for a `LayoutNode` JSON object.
///
/// A layout node represents a single widget instance in the layout,
/// including its type, properties, and data bindings.
extension type LayoutNode.fromMap(Map<String, Object?> _json)
    implements JsonObjectBase {
  /// Creates a new [LayoutNode] from an [id] and [type].
  ///
  /// The [properties], [bindings], and [itemTemplate] are optional.
  factory LayoutNode({
    required String id,
    required String type,
    Map<String, Object?>? properties,
    Map<String, Binding>? bindings,
    LayoutNode? itemTemplate,
  }) => LayoutNode.fromMap({
    'id': id,
    'type': type,
    if (properties != null) 'properties': properties,
    if (bindings != null)
      'bindings': bindings.map((key, value) => MapEntry(key, value.toJson())),
    if (itemTemplate != null) 'itemTemplate': itemTemplate.toJson(),
  });

  /// The unique identifier for this widget instance.
  String get id => _json['id'] as String;

  /// The type of the widget, which must match a key in the [WidgetCatalog].
  String get type => _json['type'] as String;

  /// Static properties for this widget.
  Map<String, Object?>? get properties =>
      _json['properties'] as Map<String, Object?>?;

  /// Binds widget properties to paths in the state object.
  Map<String, Binding>? get bindings {
    final bindingsMap = _json['bindings'] as Map<String, Object?>?;
    return bindingsMap?.map(
      (key, value) =>
          MapEntry(key, Binding.fromMap(value as Map<String, Object?>)),
    );
  }

  /// A template node for list builder widgets.
  LayoutNode? get itemTemplate {
    final templateJson = _json['itemTemplate'] as Map<String, Object?>?;
    return templateJson != null ? LayoutNode.fromMap(templateJson) : null;
  }
}

// -----------------------------------------------------------------------------
// Event & Update Models
// -----------------------------------------------------------------------------

/// A type-safe wrapper for an `EventPayload` JSON object.
///
/// This payload is sent from the client to the server when a user interaction
/// occurs, such as a button press.
extension type EventPayload.fromMap(Map<String, Object?> _json)
    implements JsonObjectBase {
  /// Creates a new [EventPayload] from a [sourceNodeId] and [eventName].
  ///
  /// The [arguments] are optional. The [timestamp] defaults to
  /// `DateTime.now()`.
  factory EventPayload({
    required String sourceNodeId,
    required String eventName,
    Map<String, Object?>? arguments,
    DateTime? timestamp,
  }) => EventPayload.fromMap({
    'sourceNodeId': sourceNodeId,
    'eventName': eventName,
    'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
    if (arguments != null) 'arguments': arguments,
  });

  /// The ID of the [LayoutNode] that generated the event.
  String get sourceNodeId => _json['sourceNodeId'] as String;

  /// The name of the event (e.g., `onPressed`).
  String get eventName => _json['eventName'] as String;

  /// An optional object containing contextual data.
  Map<String, Object?>? get arguments =>
      _json['arguments'] as Map<String, Object?>?;

  /// The timestamp when the event occurred.
  DateTime get timestamp => DateTime.parse(_json['timestamp'] as String);
}

/// A type-safe wrapper for a `StateUpdate` payload, which uses the JSON Patch
/// standard (RFC 6902) to deliver targeted data-only updates to the client.
extension type StateUpdate.fromMap(Map<String, Object?> _json)
    implements JsonObjectBase {
  /// Creates a new [StateUpdate] from a list of JSON Patch [patches].
  factory StateUpdate({required List<Map<String, Object?>> patches}) =>
      StateUpdate.fromMap({'patches': patches});

  /// An array of JSON Patch operation objects.
  List<Map<String, Object?>> get patches => (_json['patches'] as List<Object?>)
      .cast<Map<String, Object?>>()
      .where((element) {
        return element.keys.isNotEmpty;
      })
      .toList();
}

/// A type-safe wrapper for a `LayoutUpdate` payload, which delivers surgical
/// modifications to the UI's structure (e.g., adding or removing catalog
/// items).
extension type LayoutUpdate.fromMap(Map<String, Object?> _json)
    implements JsonObjectBase {
  /// Creates a new [LayoutUpdate] from a list of [operations].
  factory LayoutUpdate({required List<LayoutOperation> operations}) =>
      LayoutUpdate.fromMap({
        'operations': operations.map((e) => e.toJson()).toList(),
      });

  /// An array of layout modification objects.
  List<LayoutOperation> get operations {
    final opsList = _json['operations'] as List<Object?>;
    return opsList
        .cast<Map<String, Object?>>()
        .map(LayoutOperation.fromMap)
        .toList();
  }
}

/// A type-safe wrapper for a `LayoutOperation` JSON object, which represents
/// a single operation (add, remove, or replace) within a `LayoutUpdate`.
extension type LayoutOperation.fromMap(Map<String, Object?> _json)
    implements JsonObjectBase {
  /// Creates a new [LayoutOperation] from an [op] code.
  ///
  /// The other parameters are specific to the operation type.
  factory LayoutOperation({
    required String op,
    List<LayoutNode>? nodes,
    List<String>? nodeIds,
    String? targetNodeId,
    String? targetProperty,
  }) => LayoutOperation.fromMap({
    'op': op,
    if (nodes != null) 'nodes': nodes.map((e) => e.toJson()).toList(),
    if (nodeIds != null) 'nodeIds': nodeIds,
    if (targetNodeId != null) 'targetNodeId': targetNodeId,
    if (targetProperty != null) 'targetProperty': targetProperty,
  });

  /// The operation to perform (`add`, `remove`, or `replace`).
  String get op => _json['op'] as String;

  /// The nodes to add or replace.
  List<LayoutNode>? get nodes {
    final nodeList = _json['nodes'] as List<Object?>?;
    return nodeList
        ?.cast<Map<String, Object?>>()
        .map(LayoutNode.fromMap)
        .toList();
  }

  /// The IDs of the nodes to remove.
  List<String>? get nodeIds {
    final idList = _json['nodeIds'] as List<Object?>?;
    return idList?.cast<String>();
  }

  /// The ID of the target node for an `add` operation.
  String? get targetNodeId => _json['targetNodeId'] as String?;

  /// The property of the target node to add to.
  String? get targetProperty => _json['targetProperty'] as String?;
}

// -----------------------------------------------------------------------------
// State & Binding Models
// -----------------------------------------------------------------------------

/// A type-safe wrapper for a `Binding` JSON object.
///
/// A binding forges the connection between a widget property in the
/// layout and a value in the state object, with optional client-side
/// transformations.
extension type Binding.fromMap(Map<String, Object?> _json)
    implements JsonObjectBase {
  /// Creates a new [Binding] from a [path] to a value in the state.
  ///
  /// The [format], [condition], and [map] parameters are optional
  /// transformers.
  factory Binding({
    required String path,
    String? format,
    Condition? condition,
    MapTransformer? map,
  }) => Binding.fromMap({
    'path': path,
    if (format != null) 'format': format,
    if (condition != null) 'condition': condition.toJson(),
    if (map != null) 'map': map.toJson(),
  });

  /// The path to the data in the state object.
  String get path => _json['path'] as String;

  /// A string with a `{}` placeholder, which will be replaced by the value.
  String? get format => _json['format'] as String?;

  /// A conditional transformer.
  Condition? get condition {
    final conditionJson = _json['condition'] as Map<String, Object?>?;
    return conditionJson != null ? Condition.fromMap(conditionJson) : null;
  }

  /// A map transformer.
  MapTransformer? get map {
    final mapJson = _json['map'] as Map<String, Object?>?;
    return mapJson != null ? MapTransformer.fromMap(mapJson) : null;
  }

  /// Returns the underlying JSON map.
  Map<String, Object?> toJson() => _json;
}

/// A type-safe wrapper for a `Condition` transformer JSON object.
///
/// This transformer evaluates a boolean value from the state and returns one
/// of two specified values.
extension type Condition.fromMap(Map<String, Object?> _json)
    implements JsonObjectBase {
  /// Creates a new [Condition] from an optional [ifValue] and [elseValue].
  factory Condition({Object? ifValue, Object? elseValue}) => Condition.fromMap({
    if (ifValue != null) 'ifValue': ifValue,
    if (elseValue != null) 'elseValue': elseValue,
  });

  /// The value to use if the state value is `true`.
  Object? get ifValue => _json['ifValue'];

  /// The value to use if the state value is `false`.
  Object? get elseValue => _json['elseValue'];
}

/// A type-safe wrapper for a `Map` transformer JSON object.
///
/// This transformer maps a value from the state to another value, with an
/// optional fallback.
extension type MapTransformer.fromMap(Map<String, Object?> _json)
    implements JsonObjectBase {
  /// Creates a new [MapTransformer] from a [mapping] and an optional
  /// [fallback].
  factory MapTransformer({
    required Map<String, Object?> mapping,
    Object? fallback,
  }) => MapTransformer.fromMap({
    'mapping': mapping,
    if (fallback != null) 'fallback': fallback,
  });

  /// A map of possible state values to their desired output.
  Map<String, Object?> get mapping => _json['mapping'] as Map<String, Object?>;

  /// A value to use if the state value is not in the map.
  Object? get fallback => _json['fallback'];
}
