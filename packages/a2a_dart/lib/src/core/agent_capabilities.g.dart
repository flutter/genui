// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_capabilities.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AgentCapabilities _$AgentCapabilitiesFromJson(Map<String, Object?> json) =>
    _AgentCapabilities(
      streaming: json['streaming'] as bool?,
      pushNotifications: json['pushNotifications'] as bool?,
      stateTransitionHistory: json['stateTransitionHistory'] as bool?,
      extensions: (json['extensions'] as List<Object?>?)
          ?.map((e) => AgentExtension.fromJson(e as Map<String, Object?>))
          .toList(),
    );

Map<String, Object?> _$AgentCapabilitiesToJson(_AgentCapabilities instance) =>
    <String, Object?>{
      'streaming': instance.streaming,
      'pushNotifications': instance.pushNotifications,
      'stateTransitionHistory': instance.stateTransitionHistory,
      'extensions': instance.extensions?.map((e) => e.toJson()).toList(),
    };
