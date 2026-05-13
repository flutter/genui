// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';

import 'task.dart';

part 'list_tasks_result.g.dart';

/// Represents the response from the `tasks/list` RPC method.
///
/// Contains a paginated list of tasks matching the request criteria.
@JsonSerializable()
class ListTasksResult {
  /// The list of [Task] objects matching the specified filters and
  /// pagination.
  final List<Task> tasks;

  /// The total number of tasks available on the server that match the filter
  /// criteria (ignoring pagination).
  final int totalSize;

  /// The maximum number of tasks requested per page.
  final int pageSize;

  /// An opaque token for retrieving the next page of results.
  ///
  /// If this string is empty, there are no more pages.
  final String nextPageToken;

  /// Creates a [ListTasksResult] instance.
  const ListTasksResult({
    required this.tasks,
    required this.totalSize,
    required this.pageSize,
    required this.nextPageToken,
  });

  /// Deserializes a [ListTasksResult] instance from a JSON object.
  factory ListTasksResult.fromJson(Map<String, Object?> json) =>
      _$ListTasksResultFromJson(json);

  /// Creates a JSON object from a [ListTasksResult].
  Map<String, Object?> toJson() => _$ListTasksResultToJson(this);

  ListTasksResult copyWith({
    List<Task>? tasks,
    int? totalSize,
    int? pageSize,
    String? nextPageToken,
  }) {
    return ListTasksResult(
      tasks: tasks ?? this.tasks,
      totalSize: totalSize ?? this.totalSize,
      pageSize: pageSize ?? this.pageSize,
      nextPageToken: nextPageToken ?? this.nextPageToken,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListTasksResult &&
          runtimeType == other.runtimeType &&
          const DeepCollectionEquality().equals(tasks, other.tasks) &&
          totalSize == other.totalSize &&
          pageSize == other.pageSize &&
          nextPageToken == other.nextPageToken;

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(tasks) ^
      totalSize.hashCode ^
      pageSize.hashCode ^
      nextPageToken.hashCode;

  @override
  String toString() =>
      'ListTasksResult(tasks: $tasks, totalSize: $totalSize, '
      'pageSize: $pageSize, nextPageToken: $nextPageToken)';
}
