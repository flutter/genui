// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../core/push_notification.dart';
import 'a2a_server_exception.dart';
import 'handler_result.dart';
import 'request_handler.dart';
import 'task_manager.dart';

/// Handles the `tasks/pushNotificationConfig/get` RPC method.
class GetPushConfigHandler implements RequestHandler {
  final TaskManager _taskManager;

  /// Creates a [GetPushConfigHandler].
  GetPushConfigHandler(this._taskManager);

  @override
  String get method => 'tasks/pushNotificationConfig/get';

  @override
  Future<HandlerResult> handle(Map<String, Object?> params) async {
    final taskId = params['id'] as String?;
    final configId = params['pushNotificationConfigId'] as String?;

    if (taskId == null || configId == null) {
      throw A2AServerException(
        'Missing required parameters: id, pushNotificationConfigId',
        -32602,
      ); // Invalid params,
    }

    final config = await _taskManager.getPushNotificationConfig(
      taskId,
      configId,
    );
    if (config == null) {
      throw A2AServerException(
        'Push notification config not found: $configId for task $taskId',
        -32001,
      ); // Custom: Config not found,
    }

    return SingleResult(
      TaskPushNotificationConfig(
        taskId: taskId,
        pushNotificationConfig: config,
      ).toJson(),
    );
  }
}
