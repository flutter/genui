// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../core/message.dart';
import 'a2a_server_exception.dart';
import 'handler_result.dart';
import 'request_handler.dart';
import 'task_manager.dart';

/// A [RequestHandler] that creates a new task.
///
/// This handler is responsible for the `create_task` RPC method. It uses a
/// [TaskManager] to create a new task and returns the task's JSON
/// representation.
class CreateTaskHandler implements RequestHandler {
  final TaskManager _taskManager;

  /// Creates a [CreateTaskHandler].
  ///
  /// The handler will use the provided [_taskManager] to create new tasks.
  CreateTaskHandler(this._taskManager);

  @override
  String get method => 'create_task';

  @override
  FutureOr<HandlerResult> handle(Map<String, Object?> params) async {
    if (!params.containsKey('message')) {
      throw A2AServerException('`message` parameter is required.', -32602);
    }
    final message = Message.fromJson(params['message'] as Map<String, Object?>);
    final task = await _taskManager.createTask(message);
    return SingleResult(task.toJson());
  }
}
