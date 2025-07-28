import 'dart:convert';

// This is a helper, not part of the core FCP model extensions.
extension type JsonObject(Map<String, Object?> _json) {
  JsonObject.parse(String jsonString)
    : this(json.decode(jsonString) as Map<String, Object?>);
}

// Milestone 1: Core Data Models

// -----------------------------------------------------------------------------
// Manifest-related Models
// -----------------------------------------------------------------------------

/// A type-safe wrapper for the `WidgetLibraryManifest` JSON object.
///
/// The manifest is a client-defined document that specifies which widgets,
/// properties, events, and data structures the application is capable of
/// handling. It serves as a strict contract between the client and the server.
extension type WidgetLibraryManifest(Map<String, Object?> _json) {
  String get manifestVersion => _json['manifestVersion'] as String;
  Map<String, Object?> get dataTypes =>
      _json['dataTypes'] as Map<String, Object?>;
  Map<String, Object?> get widgets =>
      (_json['widgets'] as Map).cast<String, Object?>();
}

/// A type-safe wrapper for a `WidgetDefinition` JSON object.
///
/// This object describes a single renderable widget type, including its
/// supported properties and the events it can emit.
extension type WidgetDefinition(Map<String, Object?> _json) {
  Map<String, Object?> get properties =>
      _json['properties'] as Map<String, Object?>;
  Map<String, Object?>? get events => _json['events'] as Map<String, Object?>?;
}

/// A type-safe wrapper for a `PropertyDefinition` JSON object.
///
/// This object specifies the type and constraints for a single widget property.
extension type PropertyDefinition(Map<String, Object?> _json) {
  String get type => _json['type'] as String;
  List<String>? get values =>
      (_json['values'] as List<Object?>?)?.cast<String>();
  bool get isRequired => _json['isRequired'] as bool? ?? false;
  Object? get defaultValue => _json['defaultValue'];
}

// -----------------------------------------------------------------------------
// UI Packet & Layout Models
// -----------------------------------------------------------------------------

/// A type-safe wrapper for a `DynamicUIPacket` JSON object.
///
/// This is the atomic and self-contained description of a UI view at a
/// specific moment, containing the layout, state, and metadata.
extension type DynamicUIPacket(Map<String, Object?> _json) {
  String get formatVersion => _json['formatVersion'] as String;
  Layout get layout => Layout(_json['layout'] as Map<String, Object?>);
  Map<String, Object?> get state => _json['state'] as Map<String, Object?>;
  Map<String, Object?>? get metadata =>
      _json['metadata'] as Map<String, Object?>?;
}

/// A type-safe wrapper for a `Layout` JSON object.
///
/// The layout defines the UI structure using a flat adjacency list model,
/// where parent-child relationships are established through ID references.
extension type Layout(Map<String, Object?> _json) {
  String get root => _json['root'] as String;
  List<WidgetNode> get nodes {
    final nodeList = _json['nodes'] as List<Object?>;
    return nodeList.cast<Map<String, Object?>>().map(WidgetNode.new).toList();
  }
}

/// A type-safe wrapper for a `WidgetNode` JSON object.
///
/// A widget node represents a single widget instance in the layout, including
/// its type, properties, and data bindings.
extension type WidgetNode(Map<String, Object?> _json) {
  WidgetNode.fromJson(Map<String, Object?> json) : this(json);

  String get id => _json['id'] as String;
  String get type => _json['type'] as String;
  Map<String, Object?>? get properties =>
      _json['properties'] as Map<String, Object?>?;
  Map<String, Binding>? get bindings {
    final bindingsMap = _json['bindings'] as Map<String, Object?>?;
    return bindingsMap?.map(
      (key, value) => MapEntry(key, Binding(value as Map<String, Object?>)),
    );
  }

  WidgetNode? get itemTemplate {
    final templateJson = _json['itemTemplate'] as Map<String, Object?>?;
    return templateJson != null ? WidgetNode(templateJson) : null;
  }
}

// -----------------------------------------------------------------------------
// Event & Update Models
// -----------------------------------------------------------------------------

/// A type-safe wrapper for an `EventPayload` JSON object.
///
/// This payload is sent from the client to the server when a user interaction
/// occurs, such as a button press.
extension type EventPayload(Map<String, Object?> _json) {
  String get sourceWidgetId => _json['sourceWidgetId'] as String;
  String get eventName => _json['eventName'] as String;
  Map<String, Object?>? get arguments =>
      _json['arguments'] as Map<String, Object?>?;
}

/// A type-safe wrapper for a `StateUpdate` payload, which uses the JSON Patch
/// standard (RFC 6902) to deliver targeted data-only updates to the client.
extension type StateUpdate(Map<String, Object?> _json) {
  List<Map<String, Object?>> get patches =>
      (_json['patches'] as List<Object?>).cast<Map<String, Object?>>();
}

/// A type-safe wrapper for a `LayoutUpdate` payload, which delivers surgical
/// modifications to the UI's structure (e.g., adding or removing widgets).
extension type LayoutUpdate(Map<String, Object?> _json) {
  List<LayoutOperation> get operations {
    final opsList = _json['operations'] as List<Object?>;
    return opsList
        .cast<Map<String, Object?>>()
        .map(LayoutOperation.new)
        .toList();
  }
}

/// A type-safe wrapper for a `LayoutOperation` JSON object, which represents
/// a single operation (add, remove, or update) within a `LayoutUpdate`.
extension type LayoutOperation(Map<String, Object?> _json) {
  String get op => _json['op'] as String;

  // For 'add' and 'update'
  List<WidgetNode>? get nodes {
    final nodeList = _json['nodes'] as List<Object?>?;
    return nodeList?.cast<Map<String, Object?>>().map(WidgetNode.new).toList();
  }

  // For 'remove'
  List<String>? get ids {
    final idList = _json['ids'] as List<Object?>?;
    return idList?.cast<String>();
  }

  // For 'add'
  String? get targetId => _json['targetId'] as String?;
  String? get targetProperty => _json['targetProperty'] as String?;
}

// -----------------------------------------------------------------------------
// Milestone 2: State & Binding Models
// -----------------------------------------------------------------------------

/// A type-safe wrapper for a `Binding` JSON object.
///
/// A binding forges the connection between a widget property in the layout and
/// a value in the state object, with optional client-side transformations.
extension type Binding(Map<String, Object?> _json) {
  Binding.fromJson(Map<String, Object?> json) : this(json);

  String get path => _json['path'] as String;
  String? get format => _json['format'] as String?;
  Condition? get condition {
    final conditionJson = _json['condition'] as Map<String, Object?>?;
    return conditionJson != null ? Condition(conditionJson) : null;
  }

  MapTransformer? get map {
    final mapJson = _json['map'] as Map<String, Object?>?;
    return mapJson != null ? MapTransformer(mapJson) : null;
  }

  Map<String, Object?> toJson() => _json;
}

/// A type-safe wrapper for a `Condition` transformer JSON object.
///
/// This transformer evaluates a boolean value from the state and returns one
/// of two specified values.
extension type Condition(Map<String, Object?> _json) {
  Object? get ifValue => _json['if'];
  Object? get elseValue => _json['else'];
}

/// A type-safe wrapper for a `Map` transformer JSON object.
///
/// This transformer maps a value from the state to another value, with an
/// optional fallback.
extension type MapTransformer(Map<String, Object?> _json) {
  Map<String, Object?> get mapping => _json['mapping'] as Map<String, Object?>;
  Object? get fallback => _json['fallback'];
}
