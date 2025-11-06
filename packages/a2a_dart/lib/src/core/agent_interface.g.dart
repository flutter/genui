// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_interface.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AgentInterface _$AgentInterfaceFromJson(Map<String, Object?> json) =>
    _AgentInterface(
      url: json['url'] as String,
      transport: $enumDecode(_$TransportProtocolEnumMap, json['transport']),
    );

Map<String, Object?> _$AgentInterfaceToJson(_AgentInterface instance) =>
    <String, Object?>{
      'url': instance.url,
      'transport': _$TransportProtocolEnumMap[instance.transport]!,
    };

const _$TransportProtocolEnumMap = {
  TransportProtocol.jsonrpc: 'JSONRPC',
  TransportProtocol.grpc: 'GRPC',
  TransportProtocol.httpJson: 'HTTP+JSON',
};
