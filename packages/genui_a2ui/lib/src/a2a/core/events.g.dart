// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: specify_nonobvious_property_types, duplicate_ignore

part of 'events.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StatusUpdate _$StatusUpdateFromJson(Map<String, dynamic> json) => StatusUpdate(
  kind: json['kind'] as String? ?? 'status-update',
  taskId: json['taskId'] as String,
  contextId: json['contextId'] as String,
  status: TaskStatus.fromJson(json['status'] as Map<String, dynamic>),
  final_: json['final'] as bool? ?? false,
);

Map<String, dynamic> _$StatusUpdateToJson(StatusUpdate instance) =>
    <String, dynamic>{
      'kind': instance.kind,
      'taskId': instance.taskId,
      'contextId': instance.contextId,
      'status': instance.status.toJson(),
      'final': instance.final_,
    };

TaskStatusUpdate _$TaskStatusUpdateFromJson(Map<String, dynamic> json) =>
    TaskStatusUpdate(
      kind: json['kind'] as String? ?? 'task-status-update',
      taskId: json['taskId'] as String,
      contextId: json['contextId'] as String,
      status: TaskStatus.fromJson(json['status'] as Map<String, dynamic>),
      final_: json['final'] as bool? ?? false,
    );

Map<String, dynamic> _$TaskStatusUpdateToJson(TaskStatusUpdate instance) =>
    <String, dynamic>{
      'kind': instance.kind,
      'taskId': instance.taskId,
      'contextId': instance.contextId,
      'status': instance.status.toJson(),
      'final': instance.final_,
    };

ArtifactUpdate _$ArtifactUpdateFromJson(Map<String, dynamic> json) =>
    ArtifactUpdate(
      kind: json['kind'] as String? ?? 'artifact-update',
      taskId: json['taskId'] as String,
      contextId: json['contextId'] as String,
      artifact: Artifact.fromJson(json['artifact'] as Map<String, dynamic>),
      append: json['append'] as bool,
      lastChunk: json['lastChunk'] as bool,
    );

Map<String, dynamic> _$ArtifactUpdateToJson(ArtifactUpdate instance) =>
    <String, dynamic>{
      'kind': instance.kind,
      'taskId': instance.taskId,
      'contextId': instance.contextId,
      'artifact': instance.artifact.toJson(),
      'append': instance.append,
      'lastChunk': instance.lastChunk,
    };
