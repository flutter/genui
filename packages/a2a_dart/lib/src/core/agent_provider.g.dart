// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AgentProvider _$AgentProviderFromJson(Map<String, Object?> json) =>
    _AgentProvider(
      organization: json['organization'] as String,
      url: json['url'] as String,
    );

Map<String, Object?> _$AgentProviderToJson(_AgentProvider instance) =>
    <String, Object?>{
      'organization': instance.organization,
      'url': instance.url,
    };
