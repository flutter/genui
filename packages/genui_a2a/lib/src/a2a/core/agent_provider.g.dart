// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: specify_nonobvious_property_types, duplicate_ignore, strict_raw_type, lines_longer_than_80_chars

part of 'agent_provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentProvider _$AgentProviderFromJson(Map<String, dynamic> json) =>
    AgentProvider(
      organization: json['organization'] as String,
      url: json['url'] as String,
    );

Map<String, dynamic> _$AgentProviderToJson(AgentProvider instance) =>
    <String, dynamic>{
      'organization': instance.organization,
      'url': instance.url,
    };
