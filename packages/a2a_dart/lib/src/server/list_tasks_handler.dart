// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../core/list_tasks_params.dart';
import 'handler_result.dart';
import 'request_handler.dart';
import 'task_manager.dart';

/// A [RequestHandler] that handles `tasks/list` requests.
class ListTasksHandler extends RequestHandler {
  /// Creates a [ListTasksHandler].
  ListTasksHandler(this.taskManager);

  /// The task manager used to retrieve tasks.
  final TaskManager taskManager;

  @override
  String get method => 'tasks/list';

  @override
  FutureOr<HandlerResult> handle(Map<String, Object?> params) async {
    final listTasksParams = ListTasksParams.fromJson(params);
    final tasks = await taskManager.listTasks(listTasksParams);
    return SingleResult(tasks.toJson());
  }
}
