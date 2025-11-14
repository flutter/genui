// GENERATED CODE - DO NOT MODIFY BY HAND

// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of 'events.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskStatusUpdateEvent _$TaskStatusUpdateEventFromJson(
  Map<String, dynamic> json,
) => TaskStatusUpdateEvent(
  kind: json['kind'] as String? ?? 'task_status_update',
  taskId: json['taskId'] as String,
  contextId: json['contextId'] as String,
  status: TaskStatus.fromJson(json['status'] as Map<String, dynamic>),
  final_: json['final_'] as bool,
);

Map<String, dynamic> _$TaskStatusUpdateEventToJson(
  TaskStatusUpdateEvent instance,
) => <String, dynamic>{
  'kind': instance.kind,
  'taskId': instance.taskId,
  'contextId': instance.contextId,
  'status': instance.status.toJson(),
  'final_': instance.final_,
};

TaskArtifactUpdateEvent _$TaskArtifactUpdateEventFromJson(
  Map<String, dynamic> json,
) => TaskArtifactUpdateEvent(
  kind: json['kind'] as String? ?? 'task_artifact_update',
  taskId: json['taskId'] as String,
  contextId: json['contextId'] as String,
  artifact: Artifact.fromJson(json['artifact'] as Map<String, dynamic>),
  append: json['append'] as bool,
  lastChunk: json['lastChunk'] as bool,
);

Map<String, dynamic> _$TaskArtifactUpdateEventToJson(
  TaskArtifactUpdateEvent instance,
) => <String, dynamic>{
  'kind': instance.kind,
  'taskId': instance.taskId,
  'contextId': instance.contextId,
  'artifact': instance.artifact.toJson(),
  'append': instance.append,
  'lastChunk': instance.lastChunk,
};

TaskStatusUpdate _$TaskStatusUpdateFromJson(Map<String, dynamic> json) =>
    TaskStatusUpdate(
      kind: json['kind'] as String? ?? 'task_status_update',
      taskId: json['taskId'] as String,
      contextId: json['contextId'] as String,
      status: TaskStatus.fromJson(json['status'] as Map<String, dynamic>),
      final_: json['final_'] as bool,
    );

Map<String, dynamic> _$TaskStatusUpdateToJson(TaskStatusUpdate instance) =>
    <String, dynamic>{
      'kind': instance.kind,
      'taskId': instance.taskId,
      'contextId': instance.contextId,
      'status': instance.status.toJson(),
      'final_': instance.final_,
    };

TaskArtifactUpdate _$TaskArtifactUpdateFromJson(Map<String, dynamic> json) =>
    TaskArtifactUpdate(
      kind: json['kind'] as String? ?? 'task_artifact_update',
      taskId: json['taskId'] as String,
      contextId: json['contextId'] as String,
      artifact: Artifact.fromJson(json['artifact'] as Map<String, dynamic>),
      append: json['append'] as bool,
      lastChunk: json['lastChunk'] as bool,
    );

Map<String, dynamic> _$TaskArtifactUpdateToJson(TaskArtifactUpdate instance) =>
    <String, dynamic>{
      'kind': instance.kind,
      'taskId': instance.taskId,
      'contextId': instance.contextId,
      'artifact': instance.artifact.toJson(),
      'append': instance.append,
      'lastChunk': instance.lastChunk,
    };
