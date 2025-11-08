// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'a2a_server_exception.dart';
import 'handler_result.dart';
import 'request_handler.dart';
import 'task_manager.dart';

/// Handles the `tasks/pushNotificationConfig/list` RPC method.
class ListPushConfigsHandler implements RequestHandler {
  final TaskManager _taskManager;

  /// Creates a [ListPushConfigsHandler].
  ListPushConfigsHandler(this._taskManager);

  @override
  String get method => 'tasks/pushNotificationConfig/list';

  @override
  Future<HandlerResult> handle(Map<String, Object?> params) async {
    final taskId = params['id'] as String?;

    if (taskId == null) {
      throw A2AServerException(
        'Missing required parameter: id',
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

    final configs = await _taskManager.listPushNotificationConfigs(taskId);
    return SingleResult({'configs': configs.map((c) => c.toJson()).toList()});
  }
}
