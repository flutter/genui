// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../../a2a_dart.dart';

/// A [RequestHandler] that handles `tasks/get` requests.
class GetTaskHandler extends RequestHandler {
  /// Creates a [GetTaskHandler].
  GetTaskHandler(this.taskManager);

  /// The task manager used to retrieve tasks.
  final TaskManager taskManager;

  @override
  String get method => 'tasks/get';

  @override
  FutureOr<HandlerResult> handle(Map<String, Object?> params) async {
    final taskId = params['id'] as String?;
    if (taskId == null) {
      throw A2AServerException('`id` parameter is required.', -32602);
    }

    final task = await taskManager.getTask(taskId);
    if (task == null) {
      throw A2AServerException('Task not found', -32602);
    }
    return SingleResult(task.toJson());
  }
}
