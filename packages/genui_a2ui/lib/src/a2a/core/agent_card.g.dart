// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: specify_nonobvious_property_types, duplicate_ignore

part of 'agent_card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AgentCard _$AgentCardFromJson(Map<String, dynamic> json) => _AgentCard(
  protocolVersion: json['protocolVersion'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  url: json['url'] as String,
  preferredTransport: $enumDecodeNullable(
    _$TransportProtocolEnumMap,
    json['preferredTransport'],
  ),
  additionalInterfaces: (json['additionalInterfaces'] as List<dynamic>?)
      ?.map((e) => AgentInterface.fromJson(e as Map<String, dynamic>))
      .toList(),
  iconUrl: json['iconUrl'] as String?,
  provider: json['provider'] == null
      ? null
      : AgentProvider.fromJson(json['provider'] as Map<String, dynamic>),
  version: json['version'] as String,
  documentationUrl: json['documentationUrl'] as String?,
  capabilities: AgentCapabilities.fromJson(
    json['capabilities'] as Map<String, dynamic>,
  ),
  securitySchemes: (json['securitySchemes'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, SecurityScheme.fromJson(e as Map<String, dynamic>)),
  ),
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
  defaultInputModes: (json['defaultInputModes'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  defaultOutputModes: (json['defaultOutputModes'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  skills: (json['skills'] as List<dynamic>)
      .map((e) => AgentSkill.fromJson(e as Map<String, dynamic>))
      .toList(),
  supportsAuthenticatedExtendedCard:
      json['supportsAuthenticatedExtendedCard'] as bool?,
);

Map<String, dynamic> _$AgentCardToJson(
  _AgentCard instance,
) => <String, dynamic>{
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
