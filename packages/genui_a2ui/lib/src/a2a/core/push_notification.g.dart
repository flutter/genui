// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: specify_nonobvious_property_types, duplicate_ignore

part of 'push_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PushNotificationConfig _$PushNotificationConfigFromJson(
  Map<String, dynamic> json,
) => _PushNotificationConfig(
  id: json['id'] as String?,
  url: json['url'] as String,
  token: json['token'] as String?,
  authentication: json['authentication'] == null
      ? null
      : PushNotificationAuthenticationInfo.fromJson(
          json['authentication'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$PushNotificationConfigToJson(
  _PushNotificationConfig instance,
) => <String, dynamic>{
  'id': instance.id,
  'url': instance.url,
  'token': instance.token,
  'authentication': instance.authentication?.toJson(),
};

_PushNotificationAuthenticationInfo
_$PushNotificationAuthenticationInfoFromJson(Map<String, dynamic> json) =>
    _PushNotificationAuthenticationInfo(
      schemes: (json['schemes'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      credentials: json['credentials'] as String?,
    );

Map<String, dynamic> _$PushNotificationAuthenticationInfoToJson(
  _PushNotificationAuthenticationInfo instance,
) => <String, dynamic>{
  'schemes': instance.schemes,
  'credentials': instance.credentials,
};

_TaskPushNotificationConfig _$TaskPushNotificationConfigFromJson(
  Map<String, dynamic> json,
) => _TaskPushNotificationConfig(
  taskId: json['taskId'] as String,
  pushNotificationConfig: PushNotificationConfig.fromJson(
    json['pushNotificationConfig'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$TaskPushNotificationConfigToJson(
  _TaskPushNotificationConfig instance,
) => <String, dynamic>{
  'taskId': instance.taskId,
  'pushNotificationConfig': instance.pushNotificationConfig.toJson(),
};
