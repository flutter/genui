// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: specify_nonobvious_property_types, duplicate_ignore

part of 'agent_capabilities.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AgentCapabilities _$AgentCapabilitiesFromJson(Map<String, dynamic> json) =>
    _AgentCapabilities(
      streaming: json['streaming'] as bool?,
      pushNotifications: json['pushNotifications'] as bool?,
      stateTransitionHistory: json['stateTransitionHistory'] as bool?,
      extensions: (json['extensions'] as List<dynamic>?)
          ?.map((e) => AgentExtension.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AgentCapabilitiesToJson(_AgentCapabilities instance) =>
    <String, dynamic>{
      'streaming': instance.streaming,
      'pushNotifications': instance.pushNotifications,
      'stateTransitionHistory': instance.stateTransitionHistory,
      'extensions': instance.extensions?.map((e) => e.toJson()).toList(),
    };
