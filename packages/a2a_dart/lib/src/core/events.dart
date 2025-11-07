// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:freezed_annotation/freezed_annotation.dart';

import 'task.dart';

part 'events.freezed.dart';
part 'events.g.dart';

/// A discriminated union representing events sent from the server to the client
/// during a streaming task.
@Freezed(unionKey: 'kind', unionValueCase: FreezedUnionCase.snake)
abstract class StreamingEvent with _$StreamingEvent {
  /// An event indicating that the status of a task has been updated.
  const factory StreamingEvent.taskStatusUpdate({
    /// The type of this event.
    @Default('task_status_update') String kind,

    /// The unique identifier of the task that was updated.
    required String taskId,

    /// The unique identifier of the context for the task.
    required String contextId,

    /// The new status of the task.
    required TaskStatus status,

    /// If true, this is the final event in the stream for this interaction.
    required bool final_,
  }) = TaskStatusUpdateEvent;

  /// An event indicating that an artifact has been generated or updated.
  const factory StreamingEvent.taskArtifactUpdate({
    /// The type of this event.
    @Default('task_artifact_update') String kind,

    /// The ID of the task this artifact belongs to.
    required String taskId,

    /// The context ID associated with the task.
    required String contextId,

    /// The artifact that was generated or updated.
    required Artifact artifact,

    /// If true, the content of this artifact should be appended to a previously
    /// sent artifact with the same ID.
    required bool append,

    /// If true, this is the final chunk of the artifact.
    required bool lastChunk,
  }) = TaskArtifactUpdateEvent;

  /// Creates a [StreamingEvent] from a JSON object.
  factory StreamingEvent.fromJson(Map<String, Object?> json) =>
      _$StreamingEventFromJson(json);
}

/// A discriminated union representing events that can be received from the server.
///
/// This is used by the client to represent events from a stream.
@Freezed(unionKey: 'kind', unionValueCase: FreezedUnionCase.snake)
sealed class Event with _$Event {
  /// An event indicating that the status of a task has been updated.
  const factory Event.taskStatusUpdate({
    /// The type of this event.
    @Default('task_status_update') String kind,

    /// The unique identifier of the task that was updated.
    required String taskId,

    /// The unique identifier of the context for the task.
    required String contextId,

    /// The new status of the task.
    required TaskStatus status,

    /// If true, this is the final event in the stream for this interaction.
    required bool final_,
  }) = TaskStatusUpdate;

  /// An event indicating that an artifact has been generated or updated.
  const factory Event.taskArtifactUpdate({
    /// The type of this event.
    @Default('task_artifact_update') String kind,

    /// The ID of the task this artifact belongs to.
    required String taskId,

    /// The context ID associated with the task.
    required String contextId,

    /// The artifact that was generated or updated.
    required Artifact artifact,

    /// If true, the content of this artifact should be appended to a previously
    /// sent artifact with the same ID.
    required bool append,

    /// If true, this is the final chunk of the artifact.
    required bool lastChunk,
  }) = TaskArtifactUpdate;

  /// Creates an [Event] from a JSON object.
  factory Event.fromJson(Map<String, Object?> json) => _$EventFromJson(json);
}
