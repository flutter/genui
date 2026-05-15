// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport "agent_card.dart";
library;

import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../string_utils.dart';

part 'agent_skill.g.dart';

/// Represents a distinct capability or function that an agent can perform.
///
/// Part of the [AgentCard], this class allows an agent to advertise its
/// specific skills, making them discoverable to clients.
@JsonSerializable()
class AgentSkill {
  /// A unique identifier for the agent's skill (e.g., "weather-forecast").
  final String id;

  /// A human-readable name for the skill (e.g., "Weather Forecast").
  final String name;

  /// A detailed description of the skill, intended to help clients or users
  /// understand its purpose and functionality.
  final String description;

  /// A set of keywords describing the skill's capabilities.
  final List<String> tags;

  /// Example prompts or scenarios that this skill can handle, providing a
  /// hint to the client on how to use the skill.
  final List<String>? examples;

  /// The set of supported input MIME types for this skill, overriding the
  /// agent's defaults.
  final List<String>? inputModes;

  /// The set of supported output MIME types for this skill, overriding the
  /// agent's defaults.
  final List<String>? outputModes;

  /// Security schemes necessary for the agent to leverage this skill.
  final List<Map<String, List<String>>>? security;

  /// Creates an [AgentSkill].
  const AgentSkill({
    required this.id,
    required this.name,
    required this.description,
    required this.tags,
    this.examples,
    this.inputModes,
    this.outputModes,
    this.security,
  });

  /// Creates an [AgentSkill] from a JSON object.
  factory AgentSkill.fromJson(Map<String, Object?> json) =>
      _$AgentSkillFromJson(json);

  /// Creates a JSON object from a [AgentSkill].
  Map<String, Object?> toJson() => _$AgentSkillToJson(this);

  AgentSkill copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? tags,
    List<String>? examples,
    List<String>? inputModes,
    List<String>? outputModes,
    List<Map<String, List<String>>>? security,
  }) {
    return AgentSkill(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      examples: examples ?? this.examples,
      inputModes: inputModes ?? this.inputModes,
      outputModes: outputModes ?? this.outputModes,
      security: security ?? this.security,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentSkill &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          const DeepCollectionEquality().equals(tags, other.tags) &&
          const DeepCollectionEquality().equals(examples, other.examples) &&
          const DeepCollectionEquality().equals(inputModes, other.inputModes) &&
          const DeepCollectionEquality().equals(
            outputModes,
            other.outputModes,
          ) &&
          const DeepCollectionEquality().equals(security, other.security);

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    const DeepCollectionEquality().hash(tags),
    const DeepCollectionEquality().hash(examples),
    const DeepCollectionEquality().hash(inputModes),
    const DeepCollectionEquality().hash(outputModes),
    const DeepCollectionEquality().hash(security),
  );

  @override
  String toString() => buildToString('AgentSkill', {
    'id': id,
    'name': name,
    'description': description,
    'tags': tags,
    'examples': examples,
    'inputModes': inputModes,
    'outputModes': outputModes,
    'security': security,
  });
}
