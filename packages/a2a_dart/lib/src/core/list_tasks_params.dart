// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:freezed_annotation/freezed_annotation.dart';

import 'list_tasks_result.dart';
import 'task.dart';

part 'list_tasks_params.freezed.dart';
part 'list_tasks_params.g.dart';

/// Defines the parameters for the `tasks/list` RPC method.
///
/// These parameters allow clients to filter, paginate, and control the scope
/// of the task list returned by the server.
@freezed
abstract class ListTasksParams with _$ListTasksParams {
  /// Creates a [ListTasksParams] instance.
  const factory ListTasksParams({
    /// Optional. Filter tasks to only include those belonging to this specific
    /// context ID (e.g., a conversation or session).
    String? contextId,

    /// Optional. Filter tasks by their current [TaskState].
    TaskState? status,

    /// The maximum number of tasks to return in a single response.
    ///
    /// Must be between 1 and 100, inclusive. Defaults to 50.
    @Default(50) int pageSize,

    /// An opaque token used to retrieve the next page of results.
    ///
    /// This should be the value of `nextPageToken` from a previous
    /// [ListTasksResult]. If omitted, the first page is returned.
    String? pageToken,

    /// The number of recent messages to include in each task's history.
    ///
    /// Must be non-negative. Defaults to 0 (no history included).
    @Default(0) int historyLength,

    /// Optional. Filter tasks to include only those updated at or after this
    /// timestamp (in milliseconds since the Unix epoch).
    int? lastUpdatedAfter,

    /// Whether to include associated artifacts in the returned tasks.
    ///
    /// Defaults to `false` to minimize payload size. Set to `true` to retrieve
    /// artifacts.
    @Default(false) bool includeArtifacts,

    /// Optional. Request-specific metadata for extensions or custom use cases.
    Map<String, Object?>? metadata,
  }) = _ListTasksParams;

  /// Deserializes a [ListTasksParams] instance from a JSON object.
  factory ListTasksParams.fromJson(Map<String, Object?> json) =>
      _$ListTasksParamsFromJson(json);
}
