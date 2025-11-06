// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_skill.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AgentSkill _$AgentSkillFromJson(Map<String, Object?> json) => _AgentSkill(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  tags: (json['tags'] as List<Object?>).map((e) => e as String).toList(),
  examples: (json['examples'] as List<Object?>?)
      ?.map((e) => e as String)
      .toList(),
  inputModes: (json['inputModes'] as List<Object?>?)
      ?.map((e) => e as String)
      .toList(),
  outputModes: (json['outputModes'] as List<Object?>?)
      ?.map((e) => e as String)
      .toList(),
  security: (json['security'] as List<Object?>?)
      ?.map(
        (e) => (e as Map<String, Object?>).map(
          (k, e) => MapEntry(
            k,
            (e as List<Object?>).map((e) => e as String).toList(),
          ),
        ),
      )
      .toList(),
);

Map<String, Object?> _$AgentSkillToJson(_AgentSkill instance) =>
    <String, Object?>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'tags': instance.tags,
      'examples': instance.examples,
      'inputModes': instance.inputModes,
      'outputModes': instance.outputModes,
      'security': instance.security,
    };
