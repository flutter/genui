// GENERATED CODE - DO NOT MODIFY BY HAND

// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
