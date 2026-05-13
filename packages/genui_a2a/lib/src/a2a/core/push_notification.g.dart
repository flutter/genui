// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: specify_nonobvious_property_types, duplicate_ignore, strict_raw_type, lines_longer_than_80_chars

part of 'push_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PushNotificationConfig _$PushNotificationConfigFromJson(
  Map<String, dynamic> json,
) => PushNotificationConfig(
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
  PushNotificationConfig instance,
) => <String, dynamic>{
  'id': instance.id,
  'url': instance.url,
  'token': instance.token,
  'authentication': instance.authentication?.toJson(),
};

PushNotificationAuthenticationInfo _$PushNotificationAuthenticationInfoFromJson(
  Map<String, dynamic> json,
) => PushNotificationAuthenticationInfo(
  schemes: (json['schemes'] as List<dynamic>).map((e) => e as String).toList(),
  credentials: json['credentials'] as String?,
);

Map<String, dynamic> _$PushNotificationAuthenticationInfoToJson(
  PushNotificationAuthenticationInfo instance,
) => <String, dynamic>{
  'schemes': instance.schemes,
  'credentials': instance.credentials,
};

TaskPushNotificationConfig _$TaskPushNotificationConfigFromJson(
  Map<String, dynamic> json,
) => TaskPushNotificationConfig(
  taskId: json['taskId'] as String,
  pushNotificationConfig: PushNotificationConfig.fromJson(
    json['pushNotificationConfig'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$TaskPushNotificationConfigToJson(
  TaskPushNotificationConfig instance,
) => <String, dynamic>{
  'taskId': instance.taskId,
  'pushNotificationConfig': instance.pushNotificationConfig.toJson(),
};
