// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:freezed_annotation/freezed_annotation.dart';

import 'task.dart';

part 'list_tasks_params.freezed.dart';
part 'list_tasks_params.g.dart';

/// Parameters for listing tasks with optional filtering criteria.
@freezed
abstract class ListTasksParams with _$ListTasksParams {
  /// Creates a [ListTasksParams].
  const factory ListTasksParams({
    /// Filter tasks by context ID.
    String? contextId,

    /// Filter tasks by their current status state.
    TaskState? status,

    /// Maximum number of tasks to return.
    @Default(50) int pageSize,

    /// Token for pagination.
    String? pageToken,

    /// Number of recent messages to include in each task's history.
    @Default(0) int historyLength,

    /// Filter tasks updated after this timestamp (milliseconds since epoch).
    int? lastUpdatedAfter,

    /// Whether to include artifacts in the returned tasks.
    @Default(false) bool includeArtifacts,

    /// Request-specific metadata.
    Map<String, Object?>? metadata,
  }) = _ListTasksParams;

  /// Creates a [ListTasksParams] from a JSON object.
  factory ListTasksParams.fromJson(Map<String, Object?> json) =>
      _$ListTasksParamsFromJson(json);
}
