// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Message _$MessageFromJson(Map<String, Object?> json) => _Message(
  role: $enumDecode(_$RoleEnumMap, json['role']),
  parts: (json['parts'] as List<Object?>)
      .map((e) => Part.fromJson(e as Map<String, Object?>))
      .toList(),
  metadata: json['metadata'] as Map<String, Object?>?,
  extensions: (json['extensions'] as List<Object?>?)
      ?.map((e) => e as String)
      .toList(),
  referenceTaskIds: (json['referenceTaskIds'] as List<Object?>?)
      ?.map((e) => e as String)
      .toList(),
  messageId: json['messageId'] as String,
  taskId: json['taskId'] as String?,
  contextId: json['contextId'] as String?,
  kind: json['kind'] as String? ?? 'message',
);

Map<String, Object?> _$MessageToJson(_Message instance) => <String, Object?>{
  'role': _$RoleEnumMap[instance.role]!,
  'parts': instance.parts.map((e) => e.toJson()).toList(),
  'metadata': instance.metadata,
  'extensions': instance.extensions,
  'referenceTaskIds': instance.referenceTaskIds,
  'messageId': instance.messageId,
  'taskId': instance.taskId,
  'contextId': instance.contextId,
  'kind': instance.kind,
};

const _$RoleEnumMap = {Role.user: 'user', Role.agent: 'agent'};
