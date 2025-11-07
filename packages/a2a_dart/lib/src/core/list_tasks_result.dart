// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:freezed_annotation/freezed_annotation.dart';

import 'task.dart';

part 'list_tasks_result.freezed.dart';
part 'list_tasks_result.g.dart';

/// The result of a `tasks/list` RPC call.
@freezed
abstract class ListTasksResult with _$ListTasksResult {
  /// Creates a [ListTasksResult].
  const factory ListTasksResult({
    /// Array of tasks matching the specified criteria.
    required List<Task> tasks,

    /// Total number of tasks available (before pagination).
    required int totalSize,

    /// Maximum number of tasks returned in this response.
    required int pageSize,

    /// Token for retrieving the next page. An empty string if no more results
    /// are available.
    required String nextPageToken,
  }) = _ListTasksResult;

  /// Creates a [ListTasksResult] from a JSON object.
  factory ListTasksResult.fromJson(Map<String, Object?> json) =>
      _$ListTasksResultFromJson(json);
}
