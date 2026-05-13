// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';

import 'task.dart';

part 'events.g.dart';

// ignore_for_file: invalid_annotation_target

/// Represents an event received from the server, typically during a stream.
///
/// This is a discriminated union based on the `kind` field. It's used by the
/// client to handle various types of updates from the server in a type-safe
/// way.
sealed class Event {
  /// The type discriminator.
  final String kind;

  const Event({required this.kind});

  /// The unique ID of the task this event relates to.
  String get taskId;

  /// The unique context ID for the task.
  String get contextId;

  /// Deserializes an [Event] from a JSON object.
  factory Event.fromJson(Map<String, Object?> json) {
    final kind = json['kind'] as String?;
    switch (kind) {
      case 'status-update':
        return StatusUpdate.fromJson(json);
      case 'task-status-update':
        return TaskStatusUpdate.fromJson(json);
      case 'artifact-update':
        return ArtifactUpdate.fromJson(json);
      default:
        throw ArgumentError('Unknown Event kind: $kind');
    }
  }

  /// Indicates an update to the task's status.
  const factory Event.statusUpdate({
    String? kind,
    required String taskId,
    required String contextId,
    required TaskStatus status,
    bool? final_,
  }) = StatusUpdate;

  /// Indicates an update to the task's status in a streaming context.
  const factory Event.taskStatusUpdate({
    String? kind,
    required String taskId,
    required String contextId,
    required TaskStatus status,
    bool? final_,
  }) = TaskStatusUpdate;

  /// Indicates a new or updated artifact related to the task.
  const factory Event.artifactUpdate({
    String? kind,
    required String taskId,
    required String contextId,
    required Artifact artifact,
    required bool append,
    required bool lastChunk,
  }) = ArtifactUpdate;

  /// Creates a JSON object from an [Event].
  Map<String, Object?> toJson();
}

/// Indicates an update to the task's status.
@JsonSerializable()
class StatusUpdate extends Event {
  /// The unique ID of the updated task.
  @override
  final String taskId;

  /// The unique context ID for the task.
  @override
  final String contextId;

  /// The new status of the task.
  final TaskStatus status;

  /// If `true`, this is the final event for this task stream.
  @JsonKey(name: 'final')
  final bool final_;

  const StatusUpdate({
    String? kind,
    required this.taskId,
    required this.contextId,
    required this.status,
    bool? final_,
  }) : final_ = final_ ?? false,
       super(kind: kind ?? 'status-update');

  factory StatusUpdate.fromJson(Map<String, Object?> json) =>
      _$StatusUpdateFromJson(json);

  @override
  Map<String, Object?> toJson() =>
      _$StatusUpdateToJson(this)..['kind'] = 'status-update';

  StatusUpdate copyWith({
    String? taskId,
    String? contextId,
    TaskStatus? status,
    bool? final_,
  }) {
    return StatusUpdate(
      taskId: taskId ?? this.taskId,
      contextId: contextId ?? this.contextId,
      status: status ?? this.status,
      final_: final_ ?? this.final_,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatusUpdate &&
          runtimeType == other.runtimeType &&
          taskId == other.taskId &&
          contextId == other.contextId &&
          status == other.status &&
          final_ == other.final_;

  @override
  int get hashCode =>
      taskId.hashCode ^ contextId.hashCode ^ status.hashCode ^ final_.hashCode;

  @override
  String toString() =>
      'StatusUpdate(taskId: $taskId, contextId: $contextId, status: $status, '
      'final_: $final_)';
}

/// Indicates an update to the task's status in a streaming context.
@JsonSerializable()
class TaskStatusUpdate extends Event {
  /// The unique ID of the updated task.
  @override
  final String taskId;

  /// The unique context ID for the task.
  @override
  final String contextId;

  /// The new status of the task.
  final TaskStatus status;

  /// If `true`, this is the final event for this task stream.
  @JsonKey(name: 'final')
  final bool final_;

  const TaskStatusUpdate({
    String? kind,
    required this.taskId,
    required this.contextId,
    required this.status,
    bool? final_,
  }) : final_ = final_ ?? false,
       super(kind: kind ?? 'task-status-update');

  factory TaskStatusUpdate.fromJson(Map<String, Object?> json) =>
      _$TaskStatusUpdateFromJson(json);

  @override
  Map<String, Object?> toJson() =>
      _$TaskStatusUpdateToJson(this)..['kind'] = 'task-status-update';

  TaskStatusUpdate copyWith({
    String? taskId,
    String? contextId,
    TaskStatus? status,
    bool? final_,
  }) {
    return TaskStatusUpdate(
      taskId: taskId ?? this.taskId,
      contextId: contextId ?? this.contextId,
      status: status ?? this.status,
      final_: final_ ?? this.final_,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskStatusUpdate &&
          runtimeType == other.runtimeType &&
          taskId == other.taskId &&
          contextId == other.contextId &&
          status == other.status &&
          final_ == other.final_;

  @override
  int get hashCode =>
      taskId.hashCode ^ contextId.hashCode ^ status.hashCode ^ final_.hashCode;

  @override
  String toString() =>
      'TaskStatusUpdate(taskId: $taskId, contextId: $contextId, '
      'status: $status, final_: $final_)';
}

/// Indicates a new or updated artifact related to the task.
@JsonSerializable()
class ArtifactUpdate extends Event {
  /// The unique ID of the task this artifact belongs to.
  @override
  final String taskId;

  /// The unique context ID for the task.
  @override
  final String contextId;

  /// The artifact data.
  final Artifact artifact;

  /// If `true`, this artifact's content should be appended to any previous
  /// content for the same `artifact.artifactId`.
  final bool append;

  /// If `true`, this is the last chunk of data for this artifact.
  final bool lastChunk;

  const ArtifactUpdate({
    String? kind,
    required this.taskId,
    required this.contextId,
    required this.artifact,
    required this.append,
    required this.lastChunk,
  }) : super(kind: kind ?? 'artifact-update');

  factory ArtifactUpdate.fromJson(Map<String, Object?> json) =>
      _$ArtifactUpdateFromJson(json);

  @override
  Map<String, Object?> toJson() =>
      _$ArtifactUpdateToJson(this)..['kind'] = 'artifact-update';

  ArtifactUpdate copyWith({
    String? taskId,
    String? contextId,
    Artifact? artifact,
    bool? append,
    bool? lastChunk,
  }) {
    return ArtifactUpdate(
      taskId: taskId ?? this.taskId,
      contextId: contextId ?? this.contextId,
      artifact: artifact ?? this.artifact,
      append: append ?? this.append,
      lastChunk: lastChunk ?? this.lastChunk,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArtifactUpdate &&
          runtimeType == other.runtimeType &&
          taskId == other.taskId &&
          contextId == other.contextId &&
          artifact == other.artifact &&
          append == other.append &&
          lastChunk == other.lastChunk;

  @override
  int get hashCode =>
      taskId.hashCode ^
      contextId.hashCode ^
      artifact.hashCode ^
      append.hashCode ^
      lastChunk.hashCode;

  @override
  String toString() =>
      'ArtifactUpdate(taskId: $taskId, contextId: $contextId, '
      'artifact: $artifact, append: $append, lastChunk: $lastChunk)';
}
