// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../core/push_notification.dart';
import 'a2a_server_exception.dart';
import 'handler_result.dart';
import 'request_handler.dart';
import 'task_manager.dart';

/// Handles JSON-RPC requests for the `tasks/pushNotificationConfig/get` method.
///
/// This handler retrieves a specific push notification configuration for a task
/// using the [TaskManager].
class GetPushConfigHandler implements RequestHandler {
  final TaskManager _taskManager;

  /// Creates a [GetPushConfigHandler].
  ///
  /// Requires a [TaskManager] instance to access push configuration data.
  GetPushConfigHandler(this._taskManager);

  @override
  String get method => 'tasks/pushNotificationConfig/get';

  @override
  List<Map<String, List<String>>>? get securityRequirements => null;

  @override
  Future<HandlerResult> handle(Map<String, Object?> params) async {
    final taskId = params['id'] as String?;
    final configId = params['pushNotificationConfigId'] as String?;

    if (taskId == null) {
      throw A2AServerException(
        'Missing required parameter: id',
        -32602, // Invalid params
      );
    }
    if (configId == null) {
      throw A2AServerException(
        'Missing required parameter: pushNotificationConfigId',
        -32602, // Invalid params
      );
    }

    final config = await _taskManager.getPushNotificationConfig(
      taskId,
      configId,
    );
    if (config == null) {
      throw A2AServerException(
        'Push notification config not found: $configId for task $taskId',
        -32001, // Custom: Config not found
      );
    }

    return SingleResult(
      TaskPushNotificationConfig(
        taskId: taskId,
        pushNotificationConfig: config,
      ).toJson(),
    );
  }
}
