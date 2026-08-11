// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_core/a2ui_core.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../parser/response_part.dart';
import '../primitives/protocol_version.dart';
import '../utils/schema_utils.dart';

/// A single problem found in an A2UI payload.
class A2uiValidationIssue {
  /// A human-readable description of the problem.
  final String message;

  /// The surface the offending message targets, when known.
  final String? surfaceId;

  /// The component the problem was found in, when known.
  final String? componentId;

  const A2uiValidationIssue(this.message, {this.surfaceId, this.componentId});

  @override
  String toString() {
    final location = <String>[
      if (surfaceId != null) "surface '$surfaceId'",
      if (componentId != null) "component '$componentId'",
    ];
    return location.isEmpty ? message : '$message (in ${location.join(', ')})';
  }
}

/// Validates compiled A2UI payloads against the negotiated catalogs.
///
/// This is the agent SDK's validation layer. The A2UI agent specification
/// delegates it to `A2uiValidator` in the core package;
/// `package:a2ui_core` does not ship one yet, so the checks live here and
/// operate on the `v0.9` envelopes that package models.
///
/// The checks are: envelope version, catalog identity, component existence,
/// required and unknown properties, duplicate component ids, JSON Pointer
/// syntax, and — opt in via `checkReferences` — dangling child references and
/// reference cycles.
class A2uiPayloadValidator {
  /// The catalogs the payload must conform to.
  ///
  /// An empty list disables catalog conformance checks; structural checks
  /// still run.
  final List<Catalog<ComponentApi>> catalogs;

  /// The protocol version the payload must declare.
  final ProtocolVersion protocolVersion;

  const A2uiPayloadValidator({
    required this.catalogs,
    this.protocolVersion = ProtocolVersion.current,
  });

  /// Returns every problem found in [messages].
  ///
  /// Set [partial] when validating a batch that is still streaming: checks
  /// that depend on a component being fully received (required properties,
  /// reference integrity) are skipped, because the missing pieces are still in
  /// flight rather than genuinely absent.
  List<A2uiValidationIssue> validate(
    List<AgentToRendererMessage> messages, {
    bool partial = false,
    bool checkReferences = false,
  }) {
    final issues = <A2uiValidationIssue>[];
    final definedComponents = <String, String>{};
    final references = <String, Set<String>>{};

    for (final message in messages) {
      if (message.version != protocolVersion.wireValue) {
        issues.add(
          A2uiValidationIssue(
            "Message declares version '${message.version}' but the session "
            'negotiated ${protocolVersion.wireValue}.',
          ),
        );
      }

      switch (message) {
        case CreateSurfaceMessage():
          _validateCreateSurface(message, issues);
        case UpdateComponentsMessage():
          _validateUpdateComponents(
            message,
            issues,
            definedComponents,
            references,
            partial: partial,
          );
        case UpdateDataModelMessage():
          _validateUpdateDataModel(message, issues);
        case DeleteSurfaceMessage():
          if (message.surfaceId.isEmpty) {
            issues.add(
              const A2uiValidationIssue('deleteSurface has an empty surfaceId'),
            );
          }
      }
    }

    if (checkReferences && !partial) {
      _validateReferences(definedComponents, references, issues);
    }
    return issues;
  }

  /// Validates [messages] and throws on the first problem found.
  ///
  /// All problems are reported in the error, not just the first one.
  void validateOrThrow(
    List<AgentToRendererMessage> messages, {
    bool partial = false,
    bool checkReferences = false,
  }) {
    final List<A2uiValidationIssue> issues = validate(
      messages,
      partial: partial,
      checkReferences: checkReferences,
    );
    if (issues.isEmpty) return;
    throw A2uiValidationError(
      'A2UI payload failed validation:\n'
      '${issues.map((issue) => '  - $issue').join('\n')}',
      details: issues,
    );
  }

  /// The component definition for [name] across the active catalogs.
  ComponentApi? componentFor(String name) {
    for (final Catalog<ComponentApi> catalog in catalogs) {
      final ComponentApi? component = catalog.components[name];
      if (component != null) return component;
    }
    return null;
  }

  void _validateCreateSurface(
    CreateSurfaceMessage message,
    List<A2uiValidationIssue> issues,
  ) {
    if (message.surfaceId.isEmpty) {
      issues.add(
        const A2uiValidationIssue('createSurface has an empty surfaceId'),
      );
    }
    if (catalogs.isEmpty) return;
    if (!catalogs.any((catalog) => catalog.id == message.catalogId)) {
      issues.add(
        A2uiValidationIssue(
          "createSurface references catalog '${message.catalogId}', which is "
          'not active for this session. Active catalogs: '
          '${catalogs.map((catalog) => catalog.id).join(', ')}.',
          surfaceId: message.surfaceId,
        ),
      );
    }
  }

  void _validateUpdateComponents(
    UpdateComponentsMessage message,
    List<A2uiValidationIssue> issues,
    Map<String, String> definedComponents,
    Map<String, Set<String>> references, {
    required bool partial,
  }) {
    final seenInBatch = <String>{};
    for (final Map<String, dynamic> component in message.components) {
      final Object? id = component['id'];
      if (id is! String || id.isEmpty) {
        issues.add(
          A2uiValidationIssue(
            "Component is missing a string 'id'.",
            surfaceId: message.surfaceId,
          ),
        );
        continue;
      }
      if (!seenInBatch.add(id)) {
        issues.add(
          A2uiValidationIssue(
            "Duplicate component id '$id' in one updateComponents message.",
            surfaceId: message.surfaceId,
            componentId: id,
          ),
        );
      }

      final Object? type = component['component'];
      if (type is! String || type.isEmpty) {
        if (!partial) {
          issues.add(
            A2uiValidationIssue(
              "Component is missing a string 'component' type.",
              surfaceId: message.surfaceId,
              componentId: id,
            ),
          );
        }
        continue;
      }
      definedComponents[id] = type;

      if (catalogs.isEmpty) continue;
      final ComponentApi? api = componentFor(type);
      if (api == null) {
        issues.add(
          A2uiValidationIssue(
            "Unknown component '$type'. The active catalogs define: "
            '${_knownComponentNames().join(', ')}.',
            surfaceId: message.surfaceId,
            componentId: id,
          ),
        );
        continue;
      }

      _validateProperties(
        component,
        api,
        message.surfaceId,
        id,
        issues,
        references,
        partial: partial,
      );
    }
  }

  void _validateProperties(
    Map<String, dynamic> component,
    ComponentApi api,
    String surfaceId,
    String id,
    List<A2uiValidationIssue> issues,
    Map<String, Set<String>> references, {
    required bool partial,
  }) {
    final ({Map<String, Schema> properties, Set<String> required}) flat =
        flattenSchemaProperties(api.schema);

    if (!partial) {
      for (final String name in flat.required) {
        if (!component.containsKey(name)) {
          issues.add(
            A2uiValidationIssue(
              "Component '${api.name}' is missing required property '$name'.",
              surfaceId: surfaceId,
              componentId: id,
            ),
          );
        }
      }
    }

    for (final MapEntry<String, dynamic> entry in component.entries) {
      final String name = entry.key;
      if (envelopeKeys.contains(name)) continue;
      final Schema? schema = flat.properties[name];
      if (schema == null) {
        if (flat.properties.isNotEmpty) {
          issues.add(
            A2uiValidationIssue(
              "Component '${api.name}' has no property '$name'. Declared "
              'properties: ${flat.properties.keys.join(', ')}.',
              surfaceId: surfaceId,
              componentId: id,
            ),
          );
        }
        continue;
      }

      _validateDataBindings(entry.value, name, surfaceId, id, issues);
      references
          .putIfAbsent(id, () => <String>{})
          .addAll(_referencedIds(entry.value, schema));
    }
  }

  void _validateUpdateDataModel(
    UpdateDataModelMessage message,
    List<A2uiValidationIssue> issues,
  ) {
    final String? path = message.path;
    if (path != null && !isValidJsonPointer(path)) {
      issues.add(
        A2uiValidationIssue(
          "updateDataModel path '$path' is not a valid JSON Pointer.",
          surfaceId: message.surfaceId,
        ),
      );
    }
  }

  void _validateDataBindings(
    Object? value,
    String property,
    String surfaceId,
    String id,
    List<A2uiValidationIssue> issues,
  ) {
    if (value is Map) {
      final Object? path = value['path'];
      if (value.length == 1 && path is String && !isValidJsonPointer(path)) {
        issues.add(
          A2uiValidationIssue(
            "Data binding on '$property' has an invalid JSON Pointer "
            "'$path'.",
            surfaceId: surfaceId,
            componentId: id,
          ),
        );
      }
      for (final Object? nested in value.values) {
        _validateDataBindings(nested, property, surfaceId, id, issues);
      }
    } else if (value is List) {
      for (final Object? nested in value) {
        _validateDataBindings(nested, property, surfaceId, id, issues);
      }
    }
  }

  void _validateReferences(
    Map<String, String> definedComponents,
    Map<String, Set<String>> references,
    List<A2uiValidationIssue> issues,
  ) {
    for (final MapEntry<String, Set<String>> entry in references.entries) {
      for (final String child in entry.value) {
        if (!definedComponents.containsKey(child)) {
          issues.add(
            A2uiValidationIssue(
              "Component '${entry.key}' references undefined component "
              "'$child'.",
              componentId: entry.key,
            ),
          );
        }
      }
    }

    final visited = <String>{};
    final onStack = <String>{};

    bool hasCycle(String id) {
      if (onStack.contains(id)) return true;
      if (!visited.add(id)) return false;
      onStack.add(id);
      for (final String child in references[id] ?? const <String>{}) {
        if (hasCycle(child)) return true;
      }
      onStack.remove(id);
      return false;
    }

    for (final String id in definedComponents.keys) {
      if (hasCycle(id)) {
        issues.add(
          A2uiValidationIssue(
            "Component '$id' takes part in a reference cycle.",
            componentId: id,
          ),
        );
        break;
      }
    }
  }

  /// The component ids [value] references, given its declared [schema].
  Set<String> _referencedIds(Object? value, Schema schema) {
    final String? ref = schemaRefName(schema);
    if (ref == 'ComponentId' && value is String) return {value};
    if (ref == 'ChildList') {
      if (value is List) {
        return {
          for (final Object? item in value)
            if (item is String) item,
        };
      }
      if (value is Map) {
        final Object? templateId = value['componentId'];
        if (templateId is String) return {templateId};
      }
    }
    return const {};
  }

  List<String> _knownComponentNames() => [
    for (final catalog in catalogs) ...catalog.components.keys,
  ];
}

/// Whether [pointer] is syntactically a JSON Pointer (RFC 6901).
///
/// A2UI also allows relative paths inside list templates, so a pointer that
/// does not start with `/` is accepted as long as its escape sequences are
/// well formed.
bool isValidJsonPointer(String pointer) {
  for (var i = 0; i < pointer.length; i++) {
    if (pointer[i] != '~') continue;
    if (i + 1 >= pointer.length) return false;
    final String next = pointer[i + 1];
    if (next != '0' && next != '1') return false;
  }
  return true;
}
