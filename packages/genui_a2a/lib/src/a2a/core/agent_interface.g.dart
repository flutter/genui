// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: specify_nonobvious_property_types, duplicate_ignore, strict_raw_type, lines_longer_than_80_chars

part of 'agent_interface.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AgentInterface _$AgentInterfaceFromJson(Map<String, dynamic> json) =>
    _AgentInterface(
      url: json['url'] as String,
      transport: $enumDecode(_$TransportProtocolEnumMap, json['transport']),
    );

Map<String, dynamic> _$AgentInterfaceToJson(_AgentInterface instance) =>
    <String, dynamic>{
      'url': instance.url,
      'transport': _$TransportProtocolEnumMap[instance.transport]!,
    };

const _$TransportProtocolEnumMap = {
  TransportProtocol.jsonrpc: 'JSONRPC',
  TransportProtocol.grpc: 'GRPC',
  TransportProtocol.httpJson: 'HTTP+JSON',
};
