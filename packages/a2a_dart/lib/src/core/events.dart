// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:freezed_annotation/freezed_annotation.dart';

import 'task.dart';

part 'events.freezed.dart';
part 'events.g.dart';

/// A discriminated union representing events that can be sent from the server
/// to the client during a streaming task.
@Freezed(unionKey: 'kind', unionValueCase: FreezedUnionCase.snake)
abstract class StreamingEvent with _$StreamingEvent {
  /// An event indicating that the status of a task has been updated.
  const factory StreamingEvent.taskStatusUpdate({
    /// The type of this event, always 'task_status_update'.
    @Default('task_status_update') String kind,

    /// The unique identifier of the task that was updated.
    required String taskId,

    /// The unique identifier of the context for the task.
    required String contextId,

    /// The new status of the task.
    required TaskStatus status,

    /// A boolean indicating if this is the final update for the task.
    required bool final_,
  }) = TaskStatusUpdateEvent;

  /// An event indicating that an artifact has been updated.
  const factory StreamingEvent.taskArtifactUpdate({
    /// The type of this event, always 'task_artifact_update'.
    @Default('task_artifact_update') String kind,

    /// The unique identifier of the task that was updated.
    required String taskId,

    /// The unique identifier of the context for the task.
    required String contextId,

    /// The artifact that was updated.
    required Artifact artifact,

    /// A boolean indicating if the content of the artifact should be appended
    /// to the existing content.
    required bool append,

    /// A boolean indicating if this is the last chunk of the artifact.
    required bool lastChunk,
  }) = TaskArtifactUpdateEvent;

  /// Creates a [StreamingEvent] from a JSON object.
  factory StreamingEvent.fromJson(Map<String, Object?> json) =>
      _$StreamingEventFromJson(json);
}

/// Represents a single, non-streaming event from the server.
@Freezed(unionKey: 'kind', unionValueCase: FreezedUnionCase.snake)
sealed class Event with _$Event {
  /// An event indicating that the status of a task has been updated.
  const factory Event.taskStatusUpdate({
    /// The type of this event, always 'task_status_update'.
    @Default('task_status_update') String kind,

    /// The unique identifier of the task that was updated.
    required String taskId,

    /// The unique identifier of the context for the task.
    required String contextId,

    /// The new status of the task.
    required TaskStatus status,

    /// A boolean indicating if this is the final update for the task.
    required bool final_,
  }) = TaskStatusUpdate;

  /// An event indicating that an artifact has been updated.
  const factory Event.taskArtifactUpdate({
    /// The type of this event, always 'task_artifact_update'.
    @Default('task_artifact_update') String kind,

    /// The unique identifier of the task that was updated.
    required String taskId,

    /// The unique identifier of the context for the task.
    required String contextId,

    /// The artifact that was updated.
    required Artifact artifact,

    /// A boolean indicating if the content of the artifact should be appended
    /// to the existing content.
    required bool append,

    /// A boolean indicating if this is the last chunk of the artifact.
    required bool lastChunk,
  }) = TaskArtifactUpdate;

  /// Creates an [Event] from a JSON object.
  factory Event.fromJson(Map<String, Object?> json) => _$EventFromJson(json);
}
