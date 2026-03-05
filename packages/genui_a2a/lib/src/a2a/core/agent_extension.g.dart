// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: specify_nonobvious_property_types, duplicate_ignore, strict_raw_type, lines_longer_than_80_chars

part of 'agent_extension.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AgentExtension _$AgentExtensionFromJson(Map<String, dynamic> json) =>
    _AgentExtension(
      uri: json['uri'] as String,
      description: json['description'] as String?,
      required: json['required'] as bool?,
      params: json['params'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$AgentExtensionToJson(_AgentExtension instance) =>
    <String, dynamic>{
      'uri': instance.uri,
      'description': instance.description,
      'required': instance.required,
      'params': instance.params,
    };
