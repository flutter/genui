// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AgentCard _$AgentCardFromJson(Map<String, Object?> json) => _AgentCard(
  protocolVersion: json['protocolVersion'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  url: json['url'] as String,
  preferredTransport: $enumDecodeNullable(
    _$TransportProtocolEnumMap,
    json['preferredTransport'],
  ),
  additionalInterfaces: (json['additionalInterfaces'] as List<Object?>?)
      ?.map((e) => AgentInterface.fromJson(e as Map<String, Object?>))
      .toList(),
  iconUrl: json['iconUrl'] as String?,
  provider: json['provider'] == null
      ? null
      : AgentProvider.fromJson(json['provider'] as Map<String, Object?>),
  version: json['version'] as String,
  documentationUrl: json['documentationUrl'] as String?,
  capabilities: AgentCapabilities.fromJson(
    json['capabilities'] as Map<String, Object?>,
  ),
  securitySchemes: (json['securitySchemes'] as Map<String, Object?>?)?.map(
    (k, e) => MapEntry(k, SecurityScheme.fromJson(e as Map<String, Object?>)),
  ),
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
  defaultInputModes: (json['defaultInputModes'] as List<Object?>)
      .map((e) => e as String)
      .toList(),
  defaultOutputModes: (json['defaultOutputModes'] as List<Object?>)
      .map((e) => e as String)
      .toList(),
  skills: (json['skills'] as List<Object?>)
      .map((e) => AgentSkill.fromJson(e as Map<String, Object?>))
      .toList(),
  supportsAuthenticatedExtendedCard:
      json['supportsAuthenticatedExtendedCard'] as bool?,
);

Map<String, Object?> _$AgentCardToJson(
  _AgentCard instance,
) => <String, Object?>{
  'protocolVersion': instance.protocolVersion,
  'name': instance.name,
  'description': instance.description,
  'url': instance.url,
  'preferredTransport': _$TransportProtocolEnumMap[instance.preferredTransport],
  'additionalInterfaces': instance.additionalInterfaces
      ?.map((e) => e.toJson())
      .toList(),
  'iconUrl': instance.iconUrl,
  'provider': instance.provider?.toJson(),
  'version': instance.version,
  'documentationUrl': instance.documentationUrl,
  'capabilities': instance.capabilities.toJson(),
  'securitySchemes': instance.securitySchemes?.map(
    (k, e) => MapEntry(k, e.toJson()),
  ),
  'security': instance.security,
  'defaultInputModes': instance.defaultInputModes,
  'defaultOutputModes': instance.defaultOutputModes,
  'skills': instance.skills.map((e) => e.toJson()).toList(),
  'supportsAuthenticatedExtendedCard':
      instance.supportsAuthenticatedExtendedCard,
};

const _$TransportProtocolEnumMap = {
  TransportProtocol.jsonrpc: 'JSONRPC',
  TransportProtocol.grpc: 'GRPC',
  TransportProtocol.httpJson: 'HTTP+JSON',
};
