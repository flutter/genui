// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../core/push_notification.dart';
import 'a2a_server_exception.dart';
import 'handler_result.dart';
import 'request_handler.dart';
import 'task_manager.dart';

/// Handles the `tasks/pushNotificationConfig/set` RPC method.
class SetPushConfigHandler implements RequestHandler {
  final TaskManager _taskManager;

  /// Creates a [SetPushConfigHandler].
  SetPushConfigHandler(this._taskManager);

  @override
  String get method => 'tasks/pushNotificationConfig/set';

  @override
  Future<HandlerResult> handle(Map<String, Object?> params) async {
    final taskPushConfig = TaskPushNotificationConfig.fromJson(params);
    final taskId = taskPushConfig.taskId;
    final config = taskPushConfig.pushNotificationConfig;

    final task = await _taskManager.getTask(taskId);
    if (task == null) {
      throw A2AServerException(
        'Task not found: $taskId',
        -32001,
      ); // Task not found
    }

    await _taskManager.setPushNotificationConfig(taskId, config);
    return SingleResult(taskPushConfig.toJson());
  }
}
