// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Task _$TaskFromJson(Map<String, Object?> json) => _Task(
  id: json['id'] as String,
  contextId: json['contextId'] as String,
  status: TaskStatus.fromJson(json['status'] as Map<String, Object?>),
  history: (json['history'] as List<Object?>?)
      ?.map((e) => Message.fromJson(e as Map<String, Object?>))
      .toList(),
  artifacts: (json['artifacts'] as List<Object?>?)
      ?.map((e) => Artifact.fromJson(e as Map<String, Object?>))
      .toList(),
  metadata: json['metadata'] as Map<String, Object?>?,
  kind: json['kind'] as String? ?? 'task',
);

Map<String, Object?> _$TaskToJson(_Task instance) => <String, Object?>{
  'id': instance.id,
  'contextId': instance.contextId,
  'status': instance.status.toJson(),
  'history': instance.history?.map((e) => e.toJson()).toList(),
  'artifacts': instance.artifacts?.map((e) => e.toJson()).toList(),
  'metadata': instance.metadata,
  'kind': instance.kind,
};

_TaskStatus _$TaskStatusFromJson(Map<String, Object?> json) => _TaskStatus(
  state: $enumDecode(_$TaskStateEnumMap, json['state']),
  message: json['message'] == null
      ? null
      : Message.fromJson(json['message'] as Map<String, Object?>),
  timestamp: json['timestamp'] as String?,
);

Map<String, Object?> _$TaskStatusToJson(_TaskStatus instance) =>
    <String, Object?>{
      'state': _$TaskStateEnumMap[instance.state]!,
      'message': instance.message?.toJson(),
      'timestamp': instance.timestamp,
    };

const _$TaskStateEnumMap = {
  TaskState.submitted: 'submitted',
  TaskState.working: 'working',
  TaskState.inputRequired: 'inputRequired',
  TaskState.completed: 'completed',
  TaskState.canceled: 'canceled',
  TaskState.failed: 'failed',
  TaskState.rejected: 'rejected',
  TaskState.authRequired: 'authRequired',
  TaskState.unknown: 'unknown',
};

_Artifact _$ArtifactFromJson(Map<String, Object?> json) => _Artifact(
  artifactId: json['artifactId'] as String,
  name: json['name'] as String?,
  description: json['description'] as String?,
  parts: (json['parts'] as List<Object?>)
      .map((e) => Part.fromJson(e as Map<String, Object?>))
      .toList(),
  metadata: json['metadata'] as Map<String, Object?>?,
  extensions: (json['extensions'] as List<Object?>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, Object?> _$ArtifactToJson(_Artifact instance) => <String, Object?>{
  'artifactId': instance.artifactId,
  'name': instance.name,
  'description': instance.description,
  'parts': instance.parts.map((e) => e.toJson()).toList(),
  'metadata': instance.metadata,
  'extensions': instance.extensions,
};
