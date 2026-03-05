// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'agent_card.dart';
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'agent_skill.freezed.dart';
part 'agent_skill.g.dart';

/// Represents a distinct capability or function that an agent can perform.
///
/// Part of the [AgentCard], this class allows an agent to advertise its
/// specific skills, making them discoverable to clients.
@freezed
abstract class AgentSkill with _$AgentSkill {
  /// Creates an [AgentSkill].
  const factory AgentSkill({
    /// A unique identifier for the agent's skill (e.g., "weather-forecast").
    required String id,

    /// A human-readable name for the skill (e.g., "Weather Forecast").
    required String name,

    /// A detailed description of the skill, intended to help clients or users
    /// understand its purpose and functionality.
    required String description,

    /// A set of keywords describing the skill's capabilities.
    required List<String> tags,

    /// Example prompts or scenarios that this skill can handle, providing a
    /// hint to the client on how to use the skill.
    List<String>? examples,

    /// The set of supported input MIME types for this skill, overriding the
    /// agent's defaults.
    List<String>? inputModes,

    /// The set of supported output MIME types for this skill, overriding the
    /// agent's defaults.
    List<String>? outputModes,

    /// Security schemes necessary for the agent to leverage this skill.
    List<Map<String, List<String>>>? security,
  }) = _AgentSkill;

  /// Creates an [AgentSkill] from a JSON object.
  factory AgentSkill.fromJson(Map<String, Object?> json) =>
      _$AgentSkillFromJson(json);
}
