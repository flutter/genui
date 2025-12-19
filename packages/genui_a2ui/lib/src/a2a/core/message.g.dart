// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: specify_nonobvious_property_types, duplicate_ignore

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Message _$MessageFromJson(Map<String, dynamic> json) => _Message(
  role: $enumDecode(_$RoleEnumMap, json['role']),
  parts: (json['parts'] as List<dynamic>)
      .map((e) => Part.fromJson(e as Map<String, dynamic>))
      .toList(),
  metadata: json['metadata'] as Map<String, dynamic>?,
  extensions: (json['extensions'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  referenceTaskIds: (json['referenceTaskIds'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  messageId: json['messageId'] as String,
  taskId: json['taskId'] as String?,
  contextId: json['contextId'] as String?,
  kind: json['kind'] as String? ?? 'message',
);

Map<String, dynamic> _$MessageToJson(_Message instance) => <String, dynamic>{
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
