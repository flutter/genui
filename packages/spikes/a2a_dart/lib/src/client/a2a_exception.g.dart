// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'a2a_exception.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

A2AJsonRpcException _$A2AJsonRpcExceptionFromJson(Map<String, dynamic> json) =>
    A2AJsonRpcException(
      code: (json['code'] as num).toInt(),
      message: json['message'] as String,
      data: json['data'] as Map<String, dynamic>?,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$A2AJsonRpcExceptionToJson(
        A2AJsonRpcException instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'data': instance.data,
      'runtimeType': instance.$type,
    };

A2AParsingException _$A2AParsingExceptionFromJson(Map<String, dynamic> json) =>
    A2AParsingException(
      message: json['message'] as String,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$A2AParsingExceptionToJson(
        A2AParsingException instance) =>
    <String, dynamic>{
      'message': instance.message,
      'runtimeType': instance.$type,
    };
