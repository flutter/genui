// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'a2a_server_exception.dart';
import 'handler_result.dart';
import 'request_handler.dart';
import 'task_manager.dart';

/// Handles JSON-RPC requests for the `tasks/pushNotificationConfig/delete` method.
///
/// This handler removes a specific push notification configuration from a task
/// using the [TaskManager].
class DeletePushConfigHandler implements RequestHandler {
  final TaskManager _taskManager;

  /// Creates a [DeletePushConfigHandler].
  ///
  /// Requires a [TaskManager] instance to manage push configurations.
  DeletePushConfigHandler(this._taskManager);

  @override
  String get method => 'tasks/pushNotificationConfig/delete';

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

    final task = await _taskManager.getTask(taskId);
    if (task == null) {
      throw A2AServerException(
        'Task not found: $taskId',
        -32001, // Custom: Task not found
      );
    }

    await _taskManager.deletePushNotificationConfig(taskId, configId);
    // The A2A spec says the result should be null, but our SingleResult expects
    // a Map. Returning an empty map is the closest equivalent for a successful
    // void operation.
    return SingleResult(<String, Object?>{});
  }
}
