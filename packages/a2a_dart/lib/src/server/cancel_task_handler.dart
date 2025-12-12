// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'a2a_server_exception.dart';
import 'handler_result.dart';
import 'request_handler.dart';
import 'task_manager.dart';

/// Handles JSON-RPC requests for the `tasks/cancel` method.
///
/// This handler attempts to cancel an ongoing task managed by the
/// [TaskManager].
class CancelTaskHandler extends RequestHandler {
  /// Creates a [CancelTaskHandler].
  ///
  /// Requires a [TaskManager] instance to interact with task data.
  CancelTaskHandler(this.taskManager);

  /// The task manager used to aCcess and modify task states.
  final TaskManager taskManager;

  @override
  String get method => 'tasks/cancel';

  @override
  FutureOr<HandlerResult> handle(Map<String, Object?> params) async {
    final taskId = params['id'] as String?;
    if (taskId == null) {
      throw A2AServerException(
        'Missing required parameter: id',
        -32602, // Invalid params
      );
    }
    final task = await taskManager.cancelTask(taskId);
    if (task == null) {
      throw A2AServerException(
        'Task not found: $taskId',
        -32001,
      ); // Custom: Task not found
    }
    return SingleResult(task.toJson());
  }
}
