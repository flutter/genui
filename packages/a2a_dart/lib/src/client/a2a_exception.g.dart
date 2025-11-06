// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'a2a_exception.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

A2AJsonRpcException _$A2AJsonRpcExceptionFromJson(Map<String, Object?> json) =>
    A2AJsonRpcException(
      code: (json['code'] as num).toInt(),
      message: json['message'] as String,
      data: json['data'] as Map<String, Object?>?,
      $type: json['runtimeType'] as String?,
    );

Map<String, Object?> _$A2AJsonRpcExceptionToJson(
  A2AJsonRpcException instance,
) => <String, Object?>{
  'code': instance.code,
  'message': instance.message,
  'data': instance.data,
  'runtimeType': instance.$type,
};

A2AHttpException _$A2AHttpExceptionFromJson(Map<String, Object?> json) =>
    A2AHttpException(
      statusCode: (json['statusCode'] as num).toInt(),
      reason: json['reason'] as String?,
      $type: json['runtimeType'] as String?,
    );

Map<String, Object?> _$A2AHttpExceptionToJson(A2AHttpException instance) =>
    <String, Object?>{
      'statusCode': instance.statusCode,
      'reason': instance.reason,
      'runtimeType': instance.$type,
    };

A2ANetworkException _$A2ANetworkExceptionFromJson(Map<String, Object?> json) =>
    A2ANetworkException(
      message: json['message'] as String,
      $type: json['runtimeType'] as String?,
    );

Map<String, Object?> _$A2ANetworkExceptionToJson(
  A2ANetworkException instance,
) => <String, Object?>{
  'message': instance.message,
  'runtimeType': instance.$type,
};

A2AParsingException _$A2AParsingExceptionFromJson(Map<String, Object?> json) =>
    A2AParsingException(
      message: json['message'] as String,
      $type: json['runtimeType'] as String?,
    );

Map<String, Object?> _$A2AParsingExceptionToJson(
  A2AParsingException instance,
) => <String, Object?>{
  'message': instance.message,
  'runtimeType': instance.$type,
};
