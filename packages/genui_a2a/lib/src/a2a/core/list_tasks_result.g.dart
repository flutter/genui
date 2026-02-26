// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: specify_nonobvious_property_types, duplicate_ignore, strict_raw_type, lines_longer_than_80_chars

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
