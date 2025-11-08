// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:freezed_annotation/freezed_annotation.dart';

import 'task.dart';

part 'list_tasks_result.freezed.dart';
part 'list_tasks_result.g.dart';

/// Represents the response from the `tasks/list` RPC method.
///
/// Contains a paginated list of tasks matching the request criteria.
@freezed
abstract class ListTasksResult with _$ListTasksResult {
  /// Creates a [ListTasksResult] instance.
  const factory ListTasksResult({
    /// The list of [Task] objects matching the specified filters and
    /// pagination.
    required List<Task> tasks,

    /// The total number of tasks available on the server that match the filter
    /// criteria (ignoring pagination).
    required int totalSize,

    /// The maximum number of tasks requested per page.
    required int pageSize,

    /// An opaque token for retrieving the next page of results.
    ///
    /// If this string is empty, there are no more pages.
    required String nextPageToken,
  }) = _ListTasksResult;

  /// Deserializes a [ListTasksResult] instance from a JSON object.
  factory ListTasksResult.fromJson(Map<String, Object?> json) =>
      _$ListTasksResultFromJson(json);
}
