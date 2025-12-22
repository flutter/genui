// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: specify_nonobvious_property_types, duplicate_ignore

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
