// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: specify_nonobvious_property_types, duplicate_ignore

part of 'task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Task _$TaskFromJson(Map<String, dynamic> json) => _Task(
  id: json['id'] as String,
  contextId: json['contextId'] as String,
  status: TaskStatus.fromJson(json['status'] as Map<String, dynamic>),
  history: (json['history'] as List<dynamic>?)
      ?.map((e) => Message.fromJson(e as Map<String, dynamic>))
      .toList(),
  artifacts: (json['artifacts'] as List<dynamic>?)
      ?.map((e) => Artifact.fromJson(e as Map<String, dynamic>))
      .toList(),
  metadata: json['metadata'] as Map<String, dynamic>?,
  lastUpdated: (json['lastUpdated'] as num?)?.toInt(),
  kind: json['kind'] as String? ?? 'task',
);

Map<String, dynamic> _$TaskToJson(_Task instance) => <String, dynamic>{
  'id': instance.id,
  'contextId': instance.contextId,
  'status': instance.status.toJson(),
  'history': instance.history?.map((e) => e.toJson()).toList(),
  'artifacts': instance.artifacts?.map((e) => e.toJson()).toList(),
  'metadata': instance.metadata,
  'lastUpdated': instance.lastUpdated,
  'kind': instance.kind,
};

_TaskStatus _$TaskStatusFromJson(Map<String, dynamic> json) => _TaskStatus(
  state: $enumDecode(_$TaskStateEnumMap, json['state']),
  message: json['message'] == null
      ? null
      : Message.fromJson(json['message'] as Map<String, dynamic>),
  timestamp: json['timestamp'] as String?,
);

Map<String, dynamic> _$TaskStatusToJson(_TaskStatus instance) =>
    <String, dynamic>{
      'state': _$TaskStateEnumMap[instance.state]!,
      'message': instance.message?.toJson(),
      'timestamp': instance.timestamp,
    };

const _$TaskStateEnumMap = {
  TaskState.submitted: 'submitted',
  TaskState.working: 'working',
  TaskState.inputRequired: 'input-required',
  TaskState.completed: 'completed',
  TaskState.canceled: 'canceled',
  TaskState.failed: 'failed',
  TaskState.rejected: 'rejected',
  TaskState.authRequired: 'auth-required',
  TaskState.unknown: 'unknown',
};

_Artifact _$ArtifactFromJson(Map<String, dynamic> json) => _Artifact(
  artifactId: json['artifactId'] as String,
  name: json['name'] as String?,
  description: json['description'] as String?,
  parts: (json['parts'] as List<dynamic>)
      .map((e) => Part.fromJson(e as Map<String, dynamic>))
      .toList(),
  metadata: json['metadata'] as Map<String, dynamic>?,
  extensions: (json['extensions'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$ArtifactToJson(_Artifact instance) => <String, dynamic>{
  'artifactId': instance.artifactId,
  'name': instance.name,
  'description': instance.description,
  'parts': instance.parts.map((e) => e.toJson()).toList(),
  'metadata': instance.metadata,
  'extensions': instance.extensions,
};
