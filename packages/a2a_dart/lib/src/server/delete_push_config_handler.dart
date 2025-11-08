// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'a2a_server_exception.dart';
import 'handler_result.dart';
import 'request_handler.dart';
import 'task_manager.dart';

/// Handles the `tasks/pushNotificationConfig/delete` RPC method.
class DeletePushConfigHandler implements RequestHandler {
  final TaskManager _taskManager;

  /// Creates a [DeletePushConfigHandler].
  DeletePushConfigHandler(this._taskManager);

  @override
  String get method => 'tasks/pushNotificationConfig/delete';

  @override
  List<Map<String, List<String>>>? get securityRequirements => null;

  @override
  Future<HandlerResult> handle(Map<String, Object?> params) async {
    final taskId = params['id'] as String?;
    final configId = params['pushNotificationConfigId'] as String?;

    if (taskId == null || configId == null) {
      throw A2AServerException(
        'Missing required parameters: id, pushNotificationConfigId',
        -32602,
      ); // Invalid params
    }

    final task = await _taskManager.getTask(taskId);
    if (task == null) {
      throw A2AServerException(
        'Task not found: $taskId',
        -32001,
      ); // Task not found
    }

    await _taskManager.deletePushNotificationConfig(taskId, configId);
    return SingleResult(
      <String, Object?>{},
    ); // Spec says null, but SingleResult expects a Map
  }
}
