// GENERATED CODE - DO NOT MODIFY BY HAND

// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of 'list_tasks_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ListTasksResult _$ListTasksResultFromJson(Map<String, dynamic> json) =>
    _ListTasksResult(
      tasks: (json['tasks'] as List<dynamic>)
          .map((e) => Task.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalSize: (json['totalSize'] as num).toInt(),
      pageSize: (json['pageSize'] as num).toInt(),
      nextPageToken: json['nextPageToken'] as String,
    );

Map<String, dynamic> _$ListTasksResultToJson(_ListTasksResult instance) =>
    <String, dynamic>{
      'tasks': instance.tasks.map((e) => e.toJson()).toList(),
      'totalSize': instance.totalSize,
      'pageSize': instance.pageSize,
      'nextPageToken': instance.nextPageToken,
    };
