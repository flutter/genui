// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'events.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskStatusUpdateEvent _$TaskStatusUpdateEventFromJson(
  Map<String, Object?> json,
) =>
    TaskStatusUpdateEvent(
      kind: json['kind'] as String? ?? 'task_status_update',
      taskId: json['taskId'] as String,
      contextId: json['contextId'] as String,
  status: TaskStatus.fromJson(json['status'] as Map<String, Object?>),
      final_: json['final_'] as bool,
    );

Map<String, Object?> _$TaskStatusUpdateEventToJson(
        TaskStatusUpdateEvent instance) =>
    <String, Object?>{
      'kind': instance.kind,
      'taskId': instance.taskId,
      'contextId': instance.contextId,
      'status': instance.status.toJson(),
      'final_': instance.final_,
    };

TaskArtifactUpdateEvent _$TaskArtifactUpdateEventFromJson(
  Map<String, Object?> json,
) =>
    TaskArtifactUpdateEvent(
      kind: json['kind'] as String? ?? 'task_artifact_update',
      taskId: json['taskId'] as String,
      contextId: json['contextId'] as String,
  artifact: Artifact.fromJson(json['artifact'] as Map<String, Object?>),
      append: json['append'] as bool,
      lastChunk: json['lastChunk'] as bool,
    );

Map<String, Object?> _$TaskArtifactUpdateEventToJson(
        TaskArtifactUpdateEvent instance) =>
    <String, Object?>{
      'kind': instance.kind,
      'taskId': instance.taskId,
      'contextId': instance.contextId,
      'artifact': instance.artifact.toJson(),
      'append': instance.append,
      'lastChunk': instance.lastChunk,
    };
