// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: specify_nonobvious_property_types, duplicate_ignore

part of 'agent_skill.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AgentSkill _$AgentSkillFromJson(Map<String, dynamic> json) => _AgentSkill(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
  examples: (json['examples'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  inputModes: (json['inputModes'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  outputModes: (json['outputModes'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  security: (json['security'] as List<dynamic>?)
      ?.map(
        (e) => (e as Map<String, dynamic>).map(
          (k, e) => MapEntry(
            k,
            (e as List<dynamic>).map((e) => e as String).toList(),
          ),
        ),
      )
      .toList(),
);

Map<String, dynamic> _$AgentSkillToJson(_AgentSkill instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'tags': instance.tags,
      'examples': instance.examples,
      'inputModes': instance.inputModes,
      'outputModes': instance.outputModes,
      'security': instance.security,
    };
