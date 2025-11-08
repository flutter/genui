// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../core/list_tasks_params.dart';
import 'a2a_server_exception.dart';
import 'handler_result.dart';
import 'request_handler.dart';
import 'task_manager.dart';

/// Handles JSON-RPC requests for the `tasks/list` method.
///
/// This handler retrieves a list of tasks, potentially filtered and paginated,
/// based on the provided [ListTasksParams].
class ListTasksHandler extends RequestHandler {
  /// Creates a [ListTasksHandler].
  ///
  /// Requires a [TaskManager] instance to query task data.
  ListTasksHandler(this.taskManager);

  /// The task manager used to retrieve tasks.
  final TaskManager taskManager;

  @override
  String get method => 'tasks/list';

  @override
  List<Map<String, List<String>>>? get securityRequirements => null;

  @override
  FutureOr<HandlerResult> handle(Map<String, Object?> params) async {
    try {
      final listTasksParams = ListTasksParams.fromJson(params);
      final tasks = await taskManager.listTasks(listTasksParams);
      return SingleResult(tasks.toJson());
    } on FormatException catch (e) {
      throw A2AServerException(
        'Invalid parameters for tasks/list: $e',
        -32602, // Invalid params
      );
    }
  }
}
