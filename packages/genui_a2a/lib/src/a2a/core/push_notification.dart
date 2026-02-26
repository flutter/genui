// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'push_notification.freezed.dart';
part 'push_notification.g.dart';

/// Defines the configuration for setting up push notifications for task
/// updates.
@freezed
abstract class PushNotificationConfig with _$PushNotificationConfig {
  /// Creates a [PushNotificationConfig].
  const factory PushNotificationConfig({
    /// A unique identifier (e.g. UUID) for the push notification configuration,
    /// set by the client to support multiple notification callbacks.
    String? id,

    /// The callback URL where the agent should send push notifications.
    required String url,

    /// A unique token for this task or session to validate incoming push
    /// notifications.
    String? token,

    /// Optional authentication details for the agent to use when calling the
    /// notification URL.
    PushNotificationAuthenticationInfo? authentication,
  }) = _PushNotificationConfig;

  /// Creates a [PushNotificationConfig] from a JSON object.
  factory PushNotificationConfig.fromJson(Map<String, Object?> json) =>
      _$PushNotificationConfigFromJson(json);
}

/// Defines authentication details for a push notification endpoint.
@freezed
abstract class PushNotificationAuthenticationInfo
    with _$PushNotificationAuthenticationInfo {
  /// Creates a [PushNotificationAuthenticationInfo].
  const factory PushNotificationAuthenticationInfo({
    /// A list of supported authentication schemes (e.g., 'Basic', 'Bearer').
    required List<String> schemes,

    /// Optional credentials required by the push notification endpoint.
    String? credentials,
  }) = _PushNotificationAuthenticationInfo;

  /// Creates a [PushNotificationAuthenticationInfo] from a JSON object.
  factory PushNotificationAuthenticationInfo.fromJson(
    Map<String, Object?> json,
  ) => _$PushNotificationAuthenticationInfoFromJson(json);
}

/// A container associating a push notification configuration with a specific
/// task.
@freezed
abstract class TaskPushNotificationConfig with _$TaskPushNotificationConfig {
  /// Creates a [TaskPushNotificationConfig].
  const factory TaskPushNotificationConfig({
    /// The unique identifier (e.g. UUID) of the task.
    required String taskId,

    /// The push notification configuration for this task.
    required PushNotificationConfig pushNotificationConfig,
  }) = _TaskPushNotificationConfig;

  /// Creates a [TaskPushNotificationConfig] from a JSON object.
  factory TaskPushNotificationConfig.fromJson(Map<String, Object?> json) =>
      _$TaskPushNotificationConfigFromJson(json);
}
