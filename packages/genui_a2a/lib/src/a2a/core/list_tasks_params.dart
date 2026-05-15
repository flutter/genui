// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';

import 'list_tasks_result.dart';
import 'task.dart';

part 'list_tasks_params.g.dart';

/// Defines the parameters for the `tasks/list` RPC method.
///
/// These parameters allow clients to filter, paginate, and control the scope
/// of the task list returned by the server.
@JsonSerializable()
class ListTasksParams {
  /// Optional. Filter tasks to only include those belonging to this specific
  /// context ID (e.g., a conversation or session).
  final String? contextId;

  /// Optional. Filter tasks by their current [TaskState].
  final TaskState? status;

  /// The maximum number of tasks to return in a single response.
  ///
  /// Must be between 1 and 100, inclusive. Defaults to 50.
  final int pageSize;

  /// An opaque token used to retrieve the next page of results.
  ///
  /// This should be the value of `nextPageToken` from a previous
  /// [ListTasksResult]. If omitted, the first page is returned.
  final String? pageToken;

  /// The number of recent messages to include in each task's history.
  ///
  /// Must be non-negative. Defaults to 0 (no history included).
  final int historyLength;

  /// Optional. Filter tasks to include only those updated at or after this
  /// timestamp (in milliseconds since the Unix epoch).
  final int? lastUpdatedAfter;

  /// Whether to include associated artifacts in the returned tasks.
  ///
  /// Defaults to `false` to minimize payload size. Set to `true` to retrieve
  /// artifacts.
  final bool includeArtifacts;

  /// Optional. Request-specific metadata for extensions or custom use cases.
  final Map<String, Object?>? metadata;

  /// Creates a [ListTasksParams] instance.
  const ListTasksParams({
    this.contextId,
    this.status,
    this.pageSize = 50,
    this.pageToken,
    this.historyLength = 0,
    this.lastUpdatedAfter,
    this.includeArtifacts = false,
    this.metadata,
  });

  /// Deserializes a [ListTasksParams] instance from a JSON object.
  factory ListTasksParams.fromJson(Map<String, Object?> json) =>
      _$ListTasksParamsFromJson(json);

  /// Creates a JSON object from a [ListTasksParams].
  Map<String, Object?> toJson() => _$ListTasksParamsToJson(this);

  ListTasksParams copyWith({
    String? contextId,
    TaskState? status,
    int? pageSize,
    String? pageToken,
    int? historyLength,
    int? lastUpdatedAfter,
    bool? includeArtifacts,
    Map<String, Object?>? metadata,
  }) {
    return ListTasksParams(
      contextId: contextId ?? this.contextId,
      status: status ?? this.status,
      pageSize: pageSize ?? this.pageSize,
      pageToken: pageToken ?? this.pageToken,
      historyLength: historyLength ?? this.historyLength,
      lastUpdatedAfter: lastUpdatedAfter ?? this.lastUpdatedAfter,
      includeArtifacts: includeArtifacts ?? this.includeArtifacts,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListTasksParams &&
          runtimeType == other.runtimeType &&
          contextId == other.contextId &&
          status == other.status &&
          pageSize == other.pageSize &&
          pageToken == other.pageToken &&
          historyLength == other.historyLength &&
          lastUpdatedAfter == other.lastUpdatedAfter &&
          includeArtifacts == other.includeArtifacts &&
          const DeepCollectionEquality().equals(metadata, other.metadata);

  @override
  int get hashCode => Object.hash(
    contextId,
    status,
    pageSize,
    pageToken,
    historyLength,
    lastUpdatedAfter,
    includeArtifacts,
    const DeepCollectionEquality().hash(metadata),
  );

  @override
  String toString() =>
      '''ListTasksParams(contextId: $contextId, status: $status, pageSize: $pageSize, pageToken: $pageToken, historyLength: $historyLength, lastUpdatedAfter: $lastUpdatedAfter, includeArtifacts: $includeArtifacts, metadata: $metadata)''';
}
