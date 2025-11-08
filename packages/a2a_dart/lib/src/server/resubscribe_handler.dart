// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'a2a_server_exception.dart';
import 'handler_result.dart';
import 'request_handler.dart';
import 'task_manager.dart';

/// A [RequestHandler] that handles `tasks/resubscribe` requests.
class ResubscribeHandler extends RequestHandler {
  /// Creates a [ResubscribeHandler].
  ResubscribeHandler(this.taskManager);

  /// The task manager used to retrieve task streams.
  final TaskManager taskManager;

  @override
  String get method => 'tasks/resubscribe';

  @override
  FutureOr<HandlerResult> handle(Map<String, Object?> params) async {
    final taskId = params['id'] as String?;
    if (taskId == null) {
      throw A2AServerException('`id` parameter is required.', -32602);
    }
    final task = await taskManager.getTask(taskId);
    if (task == null) {
      throw A2AServerException('Task not found: $taskId', -32001);
    }
    final stream = taskManager.resubscribeToTask(taskId);
    return StreamResult(stream.map((event) => event.toJson()));
  }
}
