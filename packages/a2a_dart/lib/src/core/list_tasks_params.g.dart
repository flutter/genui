// GENERATED CODE - DO NOT MODIFY BY HAND

// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of 'list_tasks_params.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ListTasksParams _$ListTasksParamsFromJson(Map<String, dynamic> json) =>
    _ListTasksParams(
      contextId: json['contextId'] as String?,
      status: $enumDecodeNullable(_$TaskStateEnumMap, json['status']),
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 50,
      pageToken: json['pageToken'] as String?,
      historyLength: (json['historyLength'] as num?)?.toInt() ?? 0,
      lastUpdatedAfter: (json['lastUpdatedAfter'] as num?)?.toInt(),
      includeArtifacts: json['includeArtifacts'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ListTasksParamsToJson(_ListTasksParams instance) =>
    <String, dynamic>{
      'contextId': instance.contextId,
      'status': _$TaskStateEnumMap[instance.status],
      'pageSize': instance.pageSize,
      'pageToken': instance.pageToken,
      'historyLength': instance.historyLength,
      'lastUpdatedAfter': instance.lastUpdatedAfter,
      'includeArtifacts': instance.includeArtifacts,
      'metadata': instance.metadata,
    };

const _$TaskStateEnumMap = {
  TaskState.submitted: 'submitted',
  TaskState.working: 'working',
  TaskState.inputRequired: 'inputRequired',
  TaskState.completed: 'completed',
  TaskState.canceled: 'canceled',
  TaskState.failed: 'failed',
  TaskState.rejected: 'rejected',
  TaskState.authRequired: 'authRequired',
  TaskState.unknown: 'unknown',
};
