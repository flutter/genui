// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'a2a_server_exception.dart';
import 'handler_result.dart';
import 'request_handler.dart';
import 'task_manager.dart';

/// Handles JSON-RPC requests for the `tasks/resubscribe` method.
///
/// This handler allows a client to resume receiving events from a task's
/// stream, typically after a disconnection. It retrieves any buffered events
/// for the given task ID from the [TaskManager].
class ResubscribeHandler extends RequestHandler {
  /// Creates a [ResubscribeHandler].
  ///
  /// Requires a [TaskManager] instance to access task event streams.
  ResubscribeHandler(this.taskManager);

  /// The task manager used to retrieve task event streams.
  final TaskManager taskManager;

  @override
  String get method => 'tasks/resubscribe';

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
    try {
      final stream = taskManager.resubscribeToTask(taskId);
      return StreamResult(stream.map((event) => event.toJson()));
      // ignore: avoid_catching_errors
    } on StateError catch (e) {
      throw A2AServerException(
        'Error resubscribing to task $taskId: $e',
        -32000, // Server error
      );
    }
  }
}
