// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: specify_nonobvious_property_types, duplicate_ignore

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
  A2AJsonRpcException instance,
) => <String, dynamic>{
  'code': instance.code,
  'message': instance.message,
  'data': instance.data,
  'runtimeType': instance.$type,
};

A2ATaskNotFoundException _$A2ATaskNotFoundExceptionFromJson(
  Map<String, dynamic> json,
) => A2ATaskNotFoundException(
  message: json['message'] as String,
  data: json['data'] as Map<String, dynamic>?,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$A2ATaskNotFoundExceptionToJson(
  A2ATaskNotFoundException instance,
) => <String, dynamic>{
  'message': instance.message,
  'data': instance.data,
  'runtimeType': instance.$type,
};

A2ATaskNotCancelableException _$A2ATaskNotCancelableExceptionFromJson(
  Map<String, dynamic> json,
) => A2ATaskNotCancelableException(
  message: json['message'] as String,
  data: json['data'] as Map<String, dynamic>?,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$A2ATaskNotCancelableExceptionToJson(
  A2ATaskNotCancelableException instance,
) => <String, dynamic>{
  'message': instance.message,
  'data': instance.data,
  'runtimeType': instance.$type,
};

A2APushNotificationNotSupportedException
_$A2APushNotificationNotSupportedExceptionFromJson(Map<String, dynamic> json) =>
    A2APushNotificationNotSupportedException(
      message: json['message'] as String,
      data: json['data'] as Map<String, dynamic>?,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$A2APushNotificationNotSupportedExceptionToJson(
  A2APushNotificationNotSupportedException instance,
) => <String, dynamic>{
  'message': instance.message,
  'data': instance.data,
  'runtimeType': instance.$type,
};

A2APushNotificationConfigNotFoundException
_$A2APushNotificationConfigNotFoundExceptionFromJson(
  Map<String, dynamic> json,
) => A2APushNotificationConfigNotFoundException(
  message: json['message'] as String,
  data: json['data'] as Map<String, dynamic>?,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$A2APushNotificationConfigNotFoundExceptionToJson(
  A2APushNotificationConfigNotFoundException instance,
) => <String, dynamic>{
  'message': instance.message,
  'data': instance.data,
  'runtimeType': instance.$type,
};

A2AHttpException _$A2AHttpExceptionFromJson(Map<String, dynamic> json) =>
    A2AHttpException(
      statusCode: (json['statusCode'] as num).toInt(),
      reason: json['reason'] as String?,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$A2AHttpExceptionToJson(A2AHttpException instance) =>
    <String, dynamic>{
      'statusCode': instance.statusCode,
      'reason': instance.reason,
      'runtimeType': instance.$type,
    };

A2ANetworkException _$A2ANetworkExceptionFromJson(Map<String, dynamic> json) =>
    A2ANetworkException(
      message: json['message'] as String,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$A2ANetworkExceptionToJson(
  A2ANetworkException instance,
) => <String, dynamic>{
  'message': instance.message,
  'runtimeType': instance.$type,
};

A2AParsingException _$A2AParsingExceptionFromJson(Map<String, dynamic> json) =>
    A2AParsingException(
      message: json['message'] as String,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$A2AParsingExceptionToJson(
  A2AParsingException instance,
) => <String, dynamic>{
  'message': instance.message,
  'runtimeType': instance.$type,
};

A2AUnsupportedOperationException _$A2AUnsupportedOperationExceptionFromJson(
  Map<String, dynamic> json,
) => A2AUnsupportedOperationException(
  message: json['message'] as String,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$A2AUnsupportedOperationExceptionToJson(
  A2AUnsupportedOperationException instance,
) => <String, dynamic>{
  'message': instance.message,
  'runtimeType': instance.$type,
};
