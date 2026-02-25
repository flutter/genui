// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import 'task.dart';

part 'events.freezed.dart';
part 'events.g.dart';

/// Represents an event received from the server, typically during a stream.
///
/// This is a discriminated union based on the `kind` field. It's used by the
/// client to handle various types of updates from the server in a type-safe
/// way.
@Freezed(unionKey: 'kind', unionValueCase: FreezedUnionCase.kebab)
sealed class Event with _$Event {
  /// Indicates an update to the task's status.
  const factory Event.statusUpdate({
    /// The type of this event, always 'status-update'.
    @Default('status-update') String kind,

    /// The unique ID of the updated task.
    required String taskId,

    /// The unique context ID for the task.
    required String contextId,

    /// The new status of the task.
    required TaskStatus status,

    /// If `true`, this is the final event for this task stream.
    @JsonKey(name: 'final') @Default(false) bool final_,
  }) = StatusUpdate;

  /// Indicates an update to the task's status in a streaming context.
  const factory Event.taskStatusUpdate({
    /// The type of this event, always 'task-status-update'.
    @Default('task-status-update') String kind,

    /// The unique ID of the updated task.
    required String taskId,

    /// The unique context ID for the task.
    required String contextId,

    /// The new status of the task.
    required TaskStatus status,

    /// If `true`, this is the final event for this task stream.
    @JsonKey(name: 'final') @Default(false) bool final_,
  }) = TaskStatusUpdate;

  /// Indicates a new or updated artifact related to the task.
  const factory Event.artifactUpdate({
    /// The type of this event, always 'task-artifact-update'.
    @Default('artifact-update') String kind,

    /// The unique ID of the task this artifact belongs to.
    required String taskId,

    /// The unique context ID for the task.
    required String contextId,

    /// The artifact data.
    required Artifact artifact,

    /// If `true`, this artifact's content should be appended to any previous
    /// content for the same `artifact.artifactId`.
    required bool append,

    /// If `true`, this is the last chunk of data for this artifact.
    required bool lastChunk,
  }) = ArtifactUpdate;

  /// Deserializes an [Event] from a JSON object.
  factory Event.fromJson(Map<String, Object?> json) => _$EventFromJson(json);
}
