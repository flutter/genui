// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'agent_capabilities.dart';
library;

import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';

part 'agent_extension.g.dart';

/// Specifies an extension to the A2A protocol supported by an agent.
///
/// Used in [AgentCapabilities] to list supported protocol extensions, allowing
/// agents to advertise custom features beyond the core A2A specification.
@JsonSerializable()
class AgentExtension {
  /// The unique URI identifying the extension.
  final String uri;

  /// A human-readable description of the extension.
  final String? description;

  /// If true, the client must understand and comply with the extension's
  /// requirements to interact with the agent.
  final bool? required;

  /// Optional, extension-specific configuration parameters.
  final Map<String, Object?>? params;

  /// Creates an [AgentExtension].
  const AgentExtension({
    required this.uri,
    this.description,
    this.required,
    this.params,
  });

  /// Creates an [AgentExtension] from a JSON object.
  factory AgentExtension.fromJson(Map<String, Object?> json) =>
      _$AgentExtensionFromJson(json);

  /// Creates a JSON object from a [AgentExtension].
  Map<String, Object?> toJson() => _$AgentExtensionToJson(this);

  AgentExtension copyWith({
    String? uri,
    String? description,
    bool? required,
    Map<String, Object?>? params,
  }) {
    return AgentExtension(
      uri: uri ?? this.uri,
      description: description ?? this.description,
      required: required ?? this.required,
      params: params ?? this.params,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentExtension &&
          runtimeType == other.runtimeType &&
          uri == other.uri &&
          description == other.description &&
          required == other.required &&
          const DeepCollectionEquality().equals(params, other.params);

  @override
  int get hashCode => Object.hash(
    uri,
    description,
    required,
    const DeepCollectionEquality().hash(params),
  );

  @override
  String toString() =>
      'AgentExtension(uri: $uri, description: $description, '
      'required: $required, params: $params)';
}
