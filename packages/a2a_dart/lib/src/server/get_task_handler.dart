// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'a2a_server_exception.dart';
import 'handler_result.dart';
import 'request_handler.dart';
import 'task_manager.dart';

/// Handles JSON-RPC requests for the `tasks/get` method.
///
/// This handler retrieves the current state of a specific task by its ID
/// using the [TaskManager].
class GetTaskHandler extends RequestHandler {
  /// Creates a [GetTaskHandler].
  ///
  /// Requires a [TaskManager] instance to access task data.
  GetTaskHandler(this.taskManager);

  /// The task manager used to retrieve task information.
  final TaskManager taskManager;

  @override
  String get method => 'tasks/get';

  @override
  List<Map<String, List<String>>>? get securityRequirements => null;

  @override
  FutureOr<HandlerResult> handle(Map<String, Object?> params) async {
    final taskId = params['id'] as String?;
    if (taskId == null) {
      throw A2AServerException(
        'Missing required parameter: id',
        -32602, // Invalid params
      );
    }

    final task = await taskManager.getTask(taskId);
    if (task == null) {
      throw A2AServerException(
        'Task not found: $taskId',
        -32001, // Custom: Task not found
      );
    }
    return SingleResult(task.toJson());
  }
}
