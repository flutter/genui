// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../string_utils.dart';

part 'push_notification.g.dart';

/// Defines the configuration for setting up push notifications for task
/// updates.
@JsonSerializable()
class PushNotificationConfig {
  /// A unique identifier (e.g. UUID) for the push notification configuration,
  /// set by the client to support multiple notification callbacks.
  final String? id;

  /// The callback URL where the agent should send push notifications.
  final String url;

  /// A unique token for this task or session to validate incoming push
  /// notifications.
  final String? token;

  /// Optional authentication details for the agent to use when calling the
  /// notification URL.
  final PushNotificationAuthenticationInfo? authentication;

  /// Creates a [PushNotificationConfig].
  const PushNotificationConfig({
    this.id,
    required this.url,
    this.token,
    this.authentication,
  });

  /// Creates a [PushNotificationConfig] from a JSON object.
  factory PushNotificationConfig.fromJson(Map<String, Object?> json) =>
      _$PushNotificationConfigFromJson(json);

  /// Creates a JSON object from a [PushNotificationConfig].
  Map<String, Object?> toJson() => _$PushNotificationConfigToJson(this);

  PushNotificationConfig copyWith({
    String? id,
    String? url,
    String? token,
    PushNotificationAuthenticationInfo? authentication,
  }) {
    return PushNotificationConfig(
      id: id ?? this.id,
      url: url ?? this.url,
      token: token ?? this.token,
      authentication: authentication ?? this.authentication,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PushNotificationConfig &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          url == other.url &&
          token == other.token &&
          authentication == other.authentication;

  @override
  int get hashCode => Object.hash(id, url, token, authentication);

  @override
  String toString() => buildToString('PushNotificationConfig', {
    'id': id,
    'url': url,
    'token': token,
    'authentication': authentication,
  });
}

/// Defines authentication details for a push notification endpoint.
@JsonSerializable()
class PushNotificationAuthenticationInfo {
  /// A list of supported authentication schemes (e.g., 'Basic', 'Bearer').
  final List<String> schemes;

  /// Optional credentials required by the push notification endpoint.
  final String? credentials;

  /// Creates a [PushNotificationAuthenticationInfo].
  const PushNotificationAuthenticationInfo({
    required this.schemes,
    this.credentials,
  });

  /// Creates a [PushNotificationAuthenticationInfo] from a JSON object.
  factory PushNotificationAuthenticationInfo.fromJson(
    Map<String, Object?> json,
  ) => _$PushNotificationAuthenticationInfoFromJson(json);

  /// Creates a JSON object from a [PushNotificationAuthenticationInfo].
  Map<String, Object?> toJson() =>
      _$PushNotificationAuthenticationInfoToJson(this);

  PushNotificationAuthenticationInfo copyWith({
    List<String>? schemes,
    String? credentials,
  }) {
    return PushNotificationAuthenticationInfo(
      schemes: schemes ?? this.schemes,
      credentials: credentials ?? this.credentials,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PushNotificationAuthenticationInfo &&
          runtimeType == other.runtimeType &&
          const ListEquality<String>().equals(schemes, other.schemes) &&
          credentials == other.credentials;

  @override
  int get hashCode =>
      Object.hash(const ListEquality<String>().hash(schemes), credentials);

  @override
  String toString() => buildToString('PushNotificationAuthenticationInfo', {
    'schemes': schemes,
    'credentials': credentials,
  });
}

/// A container associating a push notification configuration with a specific
/// task.
@JsonSerializable()
class TaskPushNotificationConfig {
  /// The unique identifier (e.g. UUID) of the task.
  final String taskId;

  /// The push notification configuration for this task.
  final PushNotificationConfig pushNotificationConfig;

  /// Creates a [TaskPushNotificationConfig].
  const TaskPushNotificationConfig({
    required this.taskId,
    required this.pushNotificationConfig,
  });

  /// Creates a [TaskPushNotificationConfig] from a JSON object.
  factory TaskPushNotificationConfig.fromJson(Map<String, Object?> json) =>
      _$TaskPushNotificationConfigFromJson(json);

  /// Creates a JSON object from a [TaskPushNotificationConfig].
  Map<String, Object?> toJson() => _$TaskPushNotificationConfigToJson(this);

  TaskPushNotificationConfig copyWith({
    String? taskId,
    PushNotificationConfig? pushNotificationConfig,
  }) {
    return TaskPushNotificationConfig(
      taskId: taskId ?? this.taskId,
      pushNotificationConfig:
          pushNotificationConfig ?? this.pushNotificationConfig,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskPushNotificationConfig &&
          runtimeType == other.runtimeType &&
          taskId == other.taskId &&
          pushNotificationConfig == other.pushNotificationConfig;

  @override
  int get hashCode => Object.hash(taskId, pushNotificationConfig);

  @override
  String toString() => buildToString('TaskPushNotificationConfig', {
    'taskId': taskId,
    'pushNotificationConfig': pushNotificationConfig,
  });
}
