// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:freezed_annotation/freezed_annotation.dart';

import 'task.dart';

part 'list_tasks_params.freezed.dart';
part 'list_tasks_params.g.dart';

/// Parameters for the `tasks/list` RPC method.
@freezed
abstract class ListTasksParams with _$ListTasksParams {
  /// Creates a [ListTasksParams].
  const factory ListTasksParams({
    /// Filter tasks by context ID to get tasks from a specific conversation or
    /// session.
    String? contextId,

    /// Filter tasks by their current status.
    TaskState? status,

    /// Maximum number of tasks to return. Must be between 1 and 100.
    /// Defaults to 50 if not specified.
    @Default(50) int pageSize,

    /// Token for pagination. Use the `nextPageToken` from a previous
    /// `ListTasksResult` response.
    String? pageToken,

    /// Number of recent messages to include in each task's history. Must be
    /// non-negative. Defaults to 0 if not specified.
    @Default(0) int historyLength,

    /// Filter tasks updated after this timestamp (milliseconds since epoch).
    ///
    /// Only tasks with a last updated time greater than or equal to this value
    /// will be returned.
    int? lastUpdatedAfter,

    /// Whether to include artifacts in the returned tasks. Defaults to false to
    /// reduce payload size.
    @Default(false) bool includeArtifacts,

    /// Request-specific metadata.
    Map<String, Object?>? metadata,
  }) = _ListTasksParams;

  /// Creates a [ListTasksParams] from a JSON object.
  factory ListTasksParams.fromJson(Map<String, Object?> json) =>
      _$ListTasksParamsFromJson(json);
}
